// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTProgram.h"

#import <LTKit/NSString+Hashing.h>
#import <numeric>

#import "LTGLContext+Internal.h"
#import "LTGLException.h"
#import "LTGPUResourceProxy.h"
#import "LTProgramPool.h"
#import "LTShader.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark LTProgramObject
#pragma mark -

/// Represents an object of a GL program (attribute / uniform).
@interface LTProgramObject : NSObject

- (instancetype)initWithIndex:(GLuint)index name:(NSString *)name size:(GLint)size
                         type:(GLenum)type;

@property (readonly, nonatomic) GLuint index;
@property (strong, nonatomic) NSString *name;
@property (readonly, nonatomic) GLint size;
@property (readonly, nonatomic) GLenum type;

@end

@implementation LTProgramObject

- (instancetype)initWithIndex:(GLuint)index name:(NSString *)name size:(GLint)size
                         type:(GLenum)type {
  if (self = [super init]) {
    _index = index;
    _name = name;
    _size = size;
    _type = type;
  }
  return self;
}

@end

#pragma mark -
#pragma mark LTProgram
#pragma mark -

@interface LTProgram ()

/// YES if the program is currently bound.
@property (nonatomic) BOOL bound;

/// Set to the previously bound program, or \c 0 if program is not bound.
@property (nonatomic) GLint previousProgram;

/// Maps uniforms to their \c LTProgramObject.
@property (readonly, nonatomic) NSDictionary<NSString *, LTProgramObject *> *uniformToObject;

/// Maps attributes to their \c LTProgramObject.
@property (readonly, nonatomic) NSDictionary<NSString *, LTProgramObject *> *attributeToObject;

@end

@implementation LTProgram

@synthesize context = _context;
@synthesize name = _name;

#pragma mark -
#pragma mark Initialization and destruction
#pragma mark -

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource {
  LTGPUResourceProxy * _Nullable proxy = nil;
  if (self = [super init]) {
    _context = [LTGLContext currentContext];
    _sourceIdentifier = [[vertexSource lt_SHA1] stringByAppendingString:[fragmentSource lt_SHA1]];
    _name = [self.context.programPool nameForIdentifier:self.sourceIdentifier];

    if (![self isProgramLinked]) {
      [self linkWithVertexSource:vertexSource fragmentSource:fragmentSource];
      [self extractUniformsFromProgram];
      [self extractAttributesFromProgram];
    } else {
      [self extractUniformsFromProgram];
      [self extractAttributesFromProgram];
      [self resetState];
    }
    proxy = [[LTGPUResourceProxy alloc] initWithResource:self];
    [self.context addResource:nn((typeof(self))proxy)];
  }
  return (typeof(self))proxy;
}

- (void)dealloc {
  [self dispose];
}

- (void)dispose {
  if (!self.name || !self.context) {
    return;
  }

  [self.context removeResource:self];
  [self unbind];
  [self.context.programPool recycleName:self.name withIdentifier:self.sourceIdentifier];
  _name = 0;
}

#pragma mark -
#pragma mark Program loading
#pragma mark -

- (BOOL)isProgramLinked {
  GLint value;
  glGetProgramiv(self.name, GL_LINK_STATUS, &value);
  return value == GL_TRUE;
}

- (void)linkWithVertexSource:(NSString *)vertexSource fragmentSource:(NSString *)fragmentSource {
  // Create vertex, fragment shaders.
  LTShader *vertex = [[LTShader alloc] initWithType:LTShaderTypeVertex
                                          andSource:vertexSource];
  LTShader *fragment = [[LTShader alloc] initWithType:LTShaderTypeFragment
                                            andSource:fragmentSource];

  // Attach vertex and fragment shaders to program.
  [vertex attachToProgram:self andExecute:^{
    [fragment attachToProgram:self andExecute:^{
      [self linkProgram];
    }];
  }];
}

- (void)extractUniformsFromProgram {
  GLint uniformCount, maxUniformNameLength;
  glGetProgramiv(self.name, GL_ACTIVE_UNIFORMS, &uniformCount);
  glGetProgramiv(self.name, GL_ACTIVE_UNIFORM_MAX_LENGTH, &maxUniformNameLength);
  NSMutableDictionary *uniforms = [NSMutableDictionary dictionary];
  for (GLint i = 0; i < uniformCount; ++i) {
    LTProgramObject *object = [self uniformObjectForIndex:i maxNameLength:maxUniformNameLength];
    uniforms[object.name] = object;
  }

  _uniformToObject = [uniforms copy];
  _uniforms = [NSSet setWithArray:self.uniformToObject.allKeys];
}

- (void)extractAttributesFromProgram {
  GLint attributeCount, maxAttributeNameLength;
  glGetProgramiv(self.name, GL_ACTIVE_ATTRIBUTES, &attributeCount);
  glGetProgramiv(self.name, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &maxAttributeNameLength);
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
  for (GLint i = 0; i < attributeCount; ++i) {
    LTProgramObject *object = [self attributeObjectForIndex:i maxNameLength:maxAttributeNameLength];
    attributes[object.name] = object;
  }

  _attributeToObject = [attributes copy];
  _attributes = [NSSet setWithArray:self.attributeToObject.allKeys];
}

- (void)linkProgram {
  glLinkProgram(self.name);

#ifdef DEBUG
  GLint logLength;
  glGetProgramiv(_name, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength > 0) {
    std::unique_ptr<GLchar[]> log(new GLchar[logLength]);
    glGetProgramInfoLog(_name, logLength, NULL, log.get());
    LogWarning(@"Shader compilation info log: %s", log.get());
  }
#endif

  GLint status;
  glGetProgramiv(_name, GL_LINK_STATUS, &status);
  if (!status) {
    [LTGLException raise:kLTProgramLinkFailedException format:@"Shader link failed"];
  }
}

- (BOOL)isProgramValid {
  glValidateProgram(self.name);

#ifdef DEBUG
  GLint logLength;
  glGetProgramiv(self.name, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength > 0) {
    std::unique_ptr<GLchar[]> log(new GLchar[logLength]);
    glGetProgramInfoLog(self.name, logLength, NULL, log.get());
    LogDebug(@"Program validate log: %s", log.get());
  }
#endif

  GLint status;
  glGetProgramiv(self.name, GL_VALIDATE_STATUS, &status);
  if (status == 0) {
    return NO;
  }

  return YES;
}

- (LTProgramObject *)uniformObjectForIndex:(GLuint)index maxNameLength:(GLint)maxLength {
  GLint size;
  GLenum type;

  std::unique_ptr<GLchar[]> name(new GLchar[maxLength]);
  glGetActiveUniform(self.name, index, maxLength, NULL, &size, &type, name.get());
  LTGLCheckDbg(@"Error retrieving active uniform info");

  int uniformLocation = glGetUniformLocation(self.name, name.get());
  if (uniformLocation == -1) {
    // This should technically never happen, since we get the uniform name directly from OpenGL.
    LTAssert(NO, @"Failed to retrieve uniform location for \"%s\"", name.get());
  }

  return [[LTProgramObject alloc] initWithIndex:uniformLocation
                                           name:[NSString stringWithUTF8String:name.get()]
                                           size:size type:type];;
}

- (LTProgramObject *)attributeObjectForIndex:(GLuint)index maxNameLength:(GLint)maxLength {
  GLint size;
  GLenum type;

  std::unique_ptr<GLchar[]> name(new GLchar[maxLength]);
  glGetActiveAttrib(self.name, index, maxLength, NULL, &size, &type, name.get());
  LTGLCheckDbg(@"Error retrieving active attribute info");

  int attribLocation = glGetAttribLocation(self.name, name.get());
  if (attribLocation == -1) {
    // This should technically never happen, since we get the attribute name directly from OpenGL.
    LTAssert(NO, @"Failed to retrieve attribute location for \"%s\"", name.get());
  }

  return [[LTProgramObject alloc] initWithIndex:attribLocation
                                           name:[NSString stringWithUTF8String:name.get()]
                                           size:size type:type];;
}

#pragma mark -
#pragma mark Binding and unbinding
#pragma mark -

- (void)bind {
  if (self.bound) {
    return;
  }
  glGetIntegerv(GL_CURRENT_PROGRAM, &_previousProgram);
  glUseProgram(self.name);
  self.bound = YES;
}

- (void)unbind {
  if (!self.bound) {
    return;
  }
  glUseProgram(self.previousProgram);
  self.previousProgram = 0;
  self.bound = NO;
}

- (void)bindAndExecute:(NS_NOESCAPE LTVoidBlock)block {
  LTParameterAssert(block);
  if (self.bound) {
    block();
  } else {
    [self bind];
    block();
    [self unbind];
  }
}

#pragma mark -
#pragma mark Uniforms and attributes
#pragma mark -

/// Vector containing string representation of Objective-C's Type Encodings.
typedef std::vector<const std::string> LTTypeEncodings;

/// Mapping between a \c GLEnum representing an OpenGL unifrom type and an \c LTTypeEncodings
/// object.
typedef std::map<GLenum, const LTTypeEncodings> LTTypeToTypeEncodingsMap;

/// Returns an \c LTTypeEncodings object corresponding to passed in types.
/// usage is via the template types rather than via parameters i.e.:
/// @code
/// LTTypeEncodings en = LTEncodeTypes<char, short, int>();
/// @endcode
template <typename ...T> inline LTTypeEncodings LTEncodeTypes() {
  return {std::string(@encode(T))...};
}

/// Valid encodings for non floating point scalar types (\c GL_BOOL, \c GL_INT, \c GL_SAMPLER_2D).
static const LTTypeEncodings kNonFloatScalarEncodings =
    LTEncodeTypes<BOOL, char, short, int, long, long long, unsigned short, unsigned int,
                  unsigned long, unsigned long long>();

/// Valid encodings for floating point scalar types (\c GL_FLOAT).
static const LTTypeEncodings kFloatEncodings =
    LTEncodeTypes<BOOL, char, short, int, long, long long, unsigned short, unsigned int,
                  unsigned long, unsigned long long, float, double>();

/// Mapping between a uniform type and it's valid value types' encodings used for value verfication
/// when assigning uniforms.
static const LTTypeToTypeEncodingsMap kTypeToValidTypeEncodings = {
  {GL_BOOL, kNonFloatScalarEncodings},
  {GL_INT, kNonFloatScalarEncodings},
  {GL_SAMPLER_2D, kNonFloatScalarEncodings},
  {GL_FLOAT, kFloatEncodings},
  {GL_FLOAT_VEC2, LTEncodeTypes<LTVector2>()},
  {GL_FLOAT_VEC3, LTEncodeTypes<LTVector3>()},
  {GL_FLOAT_VEC4, LTEncodeTypes<LTVector4>()},
  {GL_FLOAT_MAT2, LTEncodeTypes<GLKMatrix2>()},
  {GL_FLOAT_MAT3, LTEncodeTypes<GLKMatrix3>()},
  {GL_FLOAT_MAT4, LTEncodeTypes<GLKMatrix4>()}
};

- (GLuint)uniformForName:(NSString *)name {
  return [self.uniformToObject[name] index];
}

- (GLuint)attributeForName:(NSString *)name {
  return [self.attributeToObject[name] index];
}

- (BOOL)containsUniform:(NSString *)name {
  return (self.uniformToObject[name] != nil);
}

- (BOOL)containsAttribute:(NSString *)name {
  return (self.attributeToObject[name] != nil);
}

- (void)setUniform:(NSString *)name withValue:(id)value {
  LTProgramObject * _Nullable object = self.uniformToObject[name];
  if (!object) {
    LTAssert(object, @"Uniform with name %@ does not exist", name);
  }
  [self verifyUniform:object value:value];

  [self bindAndExecute:^{
    switch (object.type) {
      case GL_BOOL:
      case GL_INT:
      case GL_SAMPLER_2D: {
        glUniform1i(object.index, [value intValue]);
      } break;
      case GL_FLOAT: {
        glUniform1f(object.index, [value floatValue]);
      } break;
      case GL_FLOAT_VEC2: {
        LTVector2 vector = [value LTVector2Value];
        glUniform2fv(object.index, 1, vector.data());
      } break;
      case GL_FLOAT_VEC3: {
        LTVector3 vector = [value LTVector3Value];
        glUniform3fv(object.index, 1, vector.data());
      } break;
      case GL_FLOAT_VEC4: {
        LTVector4 vector = [value LTVector4Value];
        glUniform4fv(object.index, 1, vector.data());
      } break;
      case GL_FLOAT_MAT2: {
        GLKMatrix2 matrix = [value GLKMatrix2Value];
        glUniformMatrix2fv(object.index, 1, GL_FALSE, matrix.m);
      } break;
      case GL_FLOAT_MAT3: {
        GLKMatrix3 matrix = [value GLKMatrix3Value];
        glUniformMatrix3fv(object.index, 1, GL_FALSE, matrix.m);
      } break;
      case GL_FLOAT_MAT4: {
        GLKMatrix4 matrix = [value GLKMatrix4Value];
        glUniformMatrix4fv(object.index, 1, GL_FALSE, matrix.m);
      } break;
      default:
        LTAssert(NO, @"Unsupported object type: %d, for name: %@", object.type, name);
    }
  }];
}

- (void)verifyUniform:(LTProgramObject *)uniform value:(id)value {
  LTParameterAssert(uniform.size == 1,
      @"Object '%@' is of an array type, which is currently not supported", uniform.name);

  LTParameterAssert([value isKindOfClass:[NSValue class]],
      @"Tried to set uniform '%@' and got class of type %@ instead of NSValue", uniform.name,
      [value class]);

  const std::string valueType([value objCType]);
  const LTTypeEncodings validValueTypes = kTypeToValidTypeEncodings.at(uniform.type);
  LTParameterAssert(std::find(validValueTypes.cbegin(), validValueTypes.cend(), valueType) !=
      validValueTypes.end(),
      @"Tried to set uniform '%@' and got class containing type %s instead of valid types [%@]",
      uniform.name, valueType.c_str(),
      [self typeEncodingDescription:validValueTypes delimitedBy:", "]);
}

- (NSString *)typeEncodingDescription:(const LTTypeEncodings &)encodings
                          delimitedBy:(const std::string &)delimiter {
  std::string description = std::accumulate(encodings.begin(), encodings.end(), std::string(),
      [&](const std::string & desc, const std::string & type) {
        return desc.empty() ? type : desc + delimiter + type;
      });
  return @(description.c_str());
}

- (id)uniformValue:(NSString *)name {
  LTProgramObject *object = self.uniformToObject[name];

  if (object.size != 1) {
    LTAssert(NO, @"Object '%@' is of an array type, which is currently not supported", name);
  }

  switch (object.type) {
    case GL_BOOL:
    case GL_INT:
    case GL_SAMPLER_2D: {
      GLint value;
      glGetUniformiv(self.name, object.index, &value);
      return @(value);
    }
    case GL_FLOAT: {
      float value;
      glGetUniformfv(self.name, object.index, &value);
      return @(value);
    }
    case GL_FLOAT_VEC2: {
      LTVector2 value;
      glGetUniformfv(self.name, object.index, value.data());
      return $(value);
    }
    case GL_FLOAT_VEC3: {
      LTVector3 value;
      glGetUniformfv(self.name, object.index, value.data());
      return $(value);
    }
    case GL_FLOAT_VEC4: {
      LTVector4 value;
      glGetUniformfv(self.name, object.index, value.data());
      return $(value);
    }
    case GL_FLOAT_MAT2: {
      GLKMatrix2 value;
      glGetUniformfv(self.name, object.index, value.m);
      return $(value);
    }
    case GL_FLOAT_MAT3: {
      GLKMatrix3 value;
      glGetUniformfv(self.name, object.index, value.m);
      return $(value);
    }
    case GL_FLOAT_MAT4: {
      GLKMatrix4 value;
      glGetUniformfv(self.name, object.index, value.m);
      return $(value);
    }
    default:
      LTAssert(NO, @"Unsupported object type: %d, for name: %@", object.type, name);
      return nil;
  }
}

- (void)resetState {
  [self bindAndExecute:^{
    [self.uniformToObject enumerateKeysAndObjectsUsingBlock:^(NSString *key,
                                                              LTProgramObject *object, BOOL *) {
      switch (object.type) {
        case GL_BOOL:
        case GL_INT:
        case GL_SAMPLER_2D:
          glUniform1i(object.index, 0);
          break;
        case GL_FLOAT:
          glUniform1f(object.index, 0);
          break;
        case GL_FLOAT_VEC2:
          glUniform2fv(object.index, 1, LTVector2::zeros().data());
          break;
        case GL_FLOAT_VEC3:
          glUniform3fv(object.index, 1, LTVector3::zeros().data());
          break;
        case GL_FLOAT_VEC4:
          glUniform4fv(object.index, 1, LTVector4::zeros().data());
          break;
        case GL_FLOAT_MAT2:
          static const GLKMatrix2 kMatrix2 = {{0, 0, 0, 0}};
          glUniformMatrix2fv(object.index, 1, GL_FALSE, kMatrix2.m);
          break;
        case GL_FLOAT_MAT3:
          static const GLKMatrix3 kMatrix3 = {{0, 0, 0, 0, 0, 0, 0, 0, 0}};
          glUniformMatrix3fv(object.index, 1, GL_FALSE, kMatrix3.m);
          break;
        case GL_FLOAT_MAT4:
          static const GLKMatrix4 kMatrix4 = {{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}};
          glUniformMatrix4fv(object.index, 1, GL_FALSE, kMatrix4.m);
          break;
        default:
          LTAssert(NO, @"Unsupported object type: %d, for name: %@", object.type, key);
      }
    }];
  }];
}

#pragma mark -
#pragma mark Dictionary-like access
#pragma mark -

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
  if (self.uniformToObject[key]) {
    [self setUniform:key withValue:obj];
  } else {
    LTAssert(NO, @"Given name '%@' is not a valid uniform in this program", key);
  }
}

- (id)objectForKeyedSubscript:(NSString *)key {
  if (self.uniformToObject[key]) {
    return [self uniformValue:key];
  }

  LTAssert(NO, @"Given name '%@' is not a valid uniform in this program", key);
}

@end

NS_ASSUME_NONNULL_END
