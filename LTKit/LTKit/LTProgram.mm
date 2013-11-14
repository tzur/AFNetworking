// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTProgram.h"

#import "LTGLException.h"
#import "LTShader.h"

#pragma mark -
#pragma mark LTProgramObject
#pragma mark -

/// Represents an object of a GL program (attribute / uniform).
@interface LTProgramObject : NSObject

- (id)initWithIndex:(GLuint)index name:(NSString *)name size:(GLint)size type:(GLenum)type;

@property (nonatomic) GLuint index;
@property (strong, nonatomic) NSString *name;
@property (nonatomic) GLint size;
@property (nonatomic) GLenum type;

@end

@implementation LTProgramObject

- (id)initWithIndex:(GLuint)index name:(NSString *)name size:(GLint)size type:(GLenum)type {
  if (self = [super init]) {
    self.index = index;
    self.name = name;
    self.size = size;
    self.type = type;
  }
  return self;
}

@end

#pragma mark -
#pragma mark LTProgram
#pragma mark -

@interface LTProgram ()

/// OpenGL name of the program.
@property (readwrite, nonatomic) GLuint name;

/// YES if the program is currently bounded.
@property (nonatomic) BOOL bounded;

/// Set to the previously bounded program, or \c 0 if program is not bounded.
@property (nonatomic) GLint previousProgram;

/// Maps uniforms and attributes to their index.
@property (strong, nonatomic) NSDictionary *uniforms;
@property (strong, nonatomic) NSDictionary *attributes;

@end

@implementation LTProgram

#pragma mark -
#pragma mark Initialization and destruction
#pragma mark -

- (id)initWithVertexSource:(NSString *)vertexSource fragmentSource:(NSString *)fragmentSource {
  if (self = [super init]) {
    self.attributes = [NSMutableDictionary dictionary];
    self.uniforms = [NSMutableDictionary dictionary];
    [self loadWithVertexSource:vertexSource fragmentSource:fragmentSource];
  }
  return self;
}

- (void)dealloc {
  [self teardown];
}

- (void)teardown {
  [self unbind];
  glDeleteProgram(self.name);
}

#pragma mark -
#pragma mark Program loading
#pragma mark -

- (void)loadWithVertexSource:(NSString *)vertexSource fragmentSource:(NSString *)fragmentSource {
  // Create vertex, fragment shaders.
  LTShader *vertex = [[LTShader alloc] initWithType:LTShaderTypeVertex
                                          andSource:vertexSource];
  LTShader *fragment = [[LTShader alloc] initWithType:LTShaderTypeFragment
                                            andSource:fragmentSource];
  
  // Create program.
  self.name = glCreateProgram();
  if (!LTGLCheck(@"Program creation failed")) {
    [LTGLException raise:kLTProgramCreationFailedException format:@"Error creating program"];
  }
  
  // Attach vertex and fragment shaders to program.
  [vertex bindToProgram:self];
  [fragment bindToProgram:self];
  
  [self linkProgram];
  
  // Get uniforms data. This can be done only after linking.
  GLint uniformCount, maxUniformNameLength;
  glGetProgramiv(self.name, GL_ACTIVE_UNIFORMS, &uniformCount);
  glGetProgramiv(self.name, GL_ACTIVE_UNIFORM_MAX_LENGTH, &maxUniformNameLength);
  NSMutableDictionary *uniforms = [NSMutableDictionary dictionary];
  for (GLint i = 0; i < uniformCount; ++i) {
    LTProgramObject *object = [self uniformObjectForIndex:i maxNameLength:maxUniformNameLength];
    uniforms[object.name] = object;
  }
  self.uniforms = [uniforms copy];
  
  // Get attributes data and apply attribute locations. This can be done only after linking.
  GLint attributeCount, maxAttributeNameLength;
  glGetProgramiv(self.name, GL_ACTIVE_ATTRIBUTES, &attributeCount);
  glGetProgramiv(self.name, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &maxAttributeNameLength);
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
  for (GLint i = 0; i < attributeCount; ++i) {
    LTProgramObject *object = [self attributeObjectForIndex:i maxNameLength:maxAttributeNameLength];
    attributes[object.name] = object;
  }
  self.attributes = [attributes copy];
  
  // Link again to apply attribute locations.
  [self linkProgram];
}

- (void)linkProgram {
  glLinkProgram(self.name);
  
#ifdef DEBUG
  GLint logLength;
  glGetProgramiv(_name, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength > 0) {
    std::unique_ptr<GLchar[]> log(new GLchar[logLength]);
    glGetProgramInfoLog(_name, logLength, NULL, log.get());
    [LTGLException raise:kLTProgramLinkFailedException format:@"Shader link failed: %s", log.get()];
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
  LTGLCheckExprDbg(glGetActiveUniform(self.name, index, maxLength, NULL, &size, &type, name.get()),
                   @"Error retrieving active uniform info");
  
  int uniformLocation = glGetUniformLocation(self.name, name.get());
  if (uniformLocation == -1) {
    // This should technically never happen, since we get the uniform name directly from OpenGL.
    [self teardown];
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
  LTGLCheckExprDbg(glGetActiveAttrib(self.name, index, maxLength, NULL, &size, &type, name.get()),
                   @"Error retrieving active attribute info");
  
  int attribLocation = glGetAttribLocation(self.name, name.get());
  if (attribLocation == -1) {
    // This should technically never happen, since we get the attribute name directly from OpenGL.
    [self teardown];
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
  if (self.bounded) {
    return;
  }
  glGetIntegerv(GL_CURRENT_PROGRAM, &_previousProgram);
  glUseProgram(self.name);
  self.bounded = YES;
}

- (void)unbind {
  if (!self.bounded) {
    return;
  }
  glUseProgram(self.previousProgram);
  self.previousProgram = 0;
  self.bounded = NO;
}

- (void)bindAndExecute:(LTVoidBlock)block {
  [self bind];
  if (block) block();
  [self unbind];
}

#pragma mark -
#pragma mark Uniforms and attributes
#pragma mark -

- (GLuint)uniformForName:(NSString *)name {
  return [self.uniforms[name] index];
}

- (GLuint)attributeForName:(NSString *)name {
  return [self.attributes[name] index];
}

- (BOOL)containsUniform:(NSString *)name {
  return (self.uniforms[name] != nil);
}

- (BOOL)containsAttribute:(NSString *)name {
  return (self.attributes[name] != nil);
}

- (void)setUniform:(NSString *)name withValue:(id)value {
  LTProgramObject *object = self.uniforms[name];

  if (object.size != 1) {
    LTAssert(NO, @"Object '%@' is of an array type, which is currently not supported", name);
  }
  
  [self bind];
  
  switch (object.type) {
    case GL_INT: {
      if (![value isKindOfClass:[NSNumber class]]) {
        LTAssert(NO, @"Object type is %d, but %@ class is given", object.type, [value class]);
      }
      glUniform1i(object.index, [value intValue]);
    } break;
    case GL_FLOAT: {
      if (![value isKindOfClass:[NSNumber class]]) {
        LTAssert(NO, @"Object type is %d, but %@ class is given", object.type, [value class]);
      }
      glUniform1f(object.index, [value floatValue]);
    } break;
    case GL_FLOAT_VEC2: {
      if (![value isKindOfClass:[NSValue class]]) {
        LTAssert(NO, @"Object type is %d, but %@ class is given", object.type, [value class]);
      }
      GLKVector2 vector = [value GLKVector2Value];
      glUniform2fv(object.index, 1, vector.v);
    } break;
    case GL_FLOAT_VEC3: {
      if (![value isKindOfClass:[NSValue class]]) {
        LTAssert(NO, @"Object type is %d, but %@ class is given", object.type, [value class]);
      }
      GLKVector3 vector = [value GLKVector3Value];
      glUniform3fv(object.index, 1, vector.v);
    } break;
    case GL_FLOAT_VEC4: {
      if (![value isKindOfClass:[NSValue class]]) {
        LTAssert(NO, @"Object type is %d, but %@ class is given", object.type, [value class]);
      }
      GLKVector4 vector = [value GLKVector4Value];
      glUniform4fv(object.index, 1, vector.v);
    } break;
    case GL_FLOAT_MAT2: {
      if (![value isKindOfClass:[NSValue class]]) {
        LTAssert(NO, @"Object type is %d, but %@ class is given", object.type, [value class]);
      }
      GLKMatrix2 matrix = [value GLKMatrix2Value];
      glUniformMatrix2fv(object.index, 1, GL_FALSE, matrix.m);
    } break;
    case GL_FLOAT_MAT3: {
      if (![value isKindOfClass:[NSValue class]]) {
        LTAssert(NO, @"Object type is %d, but %@ class is given", object.type, [value class]);
      }
      GLKMatrix3 matrix = [value GLKMatrix3Value];
      glUniformMatrix3fv(object.index, 1, GL_FALSE, matrix.m);
    } break;
    case GL_FLOAT_MAT4: {
      if (![value isKindOfClass:[NSValue class]]) {
        LTAssert(NO, @"Object type is %d, but %@ class is given", object.type, [value class]);
      }
      GLKMatrix4 matrix = [value GLKMatrix4Value];
      glUniformMatrix4fv(object.index, 1, GL_FALSE, matrix.m);
    } break;
    default:
      LTAssert(NO, @"Unsupported object type: %d, for name: %@", object.type, name);
  }
  
  [self unbind];
}

- (id)uniformValue:(NSString *)name {
  LTProgramObject *object = self.uniforms[name];
  
  if (object.size != 1) {
    LTAssert(NO, @"Object '%@' is of an array type, which is currently not supported", name);
  }

  switch (object.type) {
    case GL_INT: {
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
      GLKVector2 value;
      glGetUniformfv(self.name, object.index, value.v);
      return [NSValue valueWithGLKVector2:value];
    }
    case GL_FLOAT_VEC3: {
      GLKVector3 value;
      glGetUniformfv(self.name, object.index, value.v);
      return [NSValue valueWithGLKVector3:value];
    }
    case GL_FLOAT_VEC4: {
      GLKVector4 value;
      glGetUniformfv(self.name, object.index, value.v);
      return [NSValue valueWithGLKVector4:value];
    }
    case GL_FLOAT_MAT2: {
      GLKMatrix2 value;
      glGetUniformfv(self.name, object.index, value.m);
      return [NSValue valueWithGLKMatrix2:value];
    }
    case GL_FLOAT_MAT3: {
      GLKMatrix3 value;
      glGetUniformfv(self.name, object.index, value.m);
      return [NSValue valueWithGLKMatrix3:value];
    }
    case GL_FLOAT_MAT4: {
      GLKMatrix4 value;
      glGetUniformfv(self.name, object.index, value.m);
      return [NSValue valueWithGLKMatrix4:value];
    }
    default:
      LTAssert(NO, @"Unsupported object type: %d, for name: %@", object.type, name);
  }
}

#pragma mark -
#pragma mark Dictionary-like access
#pragma mark -

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key {
  if (self.uniforms[key]) {
    [self setUniform:key withValue:obj];
  } else if (self.attributes[key]) {
    // TODO:(yaron) add attribute set logic here.
  } else {
    LTAssert(NO, @"Given name '%@' is not a uniform nor attribute in this program", key);
  }
}

- (id)objectForKeyedSubscript:(NSString *)key {
  if (self.uniforms[key]) {
    return [self uniformValue:key];
  } else if (self.attributes[key]) {
    // TODO:(yaron) add attribute get logic here.
  } else {
    LTAssert(NO, @"Given name '%@' is not a uniform nor attribute in this program", key);
  }
  return nil;
}

@end
