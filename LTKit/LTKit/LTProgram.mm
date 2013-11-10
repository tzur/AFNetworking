// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTProgram.h"

#import "LTGLException.h"
#import "LTShader.h"

@interface LTProgram ()

/// OpenGL name of the program.
@property (readwrite, nonatomic) GLuint name;

/// YES if the program is currently bounded.
@property (nonatomic) BOOL bounded;

/// Set to the previously bounded program, or \c 0 if program is not bounded.
@property (nonatomic) GLint previousProgram;

/// Holds the uniforms and attributes of the shader.
@property (strong, nonatomic) NSMutableDictionary *uniforms;
@property (strong, nonatomic) NSMutableDictionary *attributes;

@end

@implementation LTProgram

#pragma mark -
#pragma mark Initialization and destruction
#pragma mark -

- (id)initWithVertexSource:(NSString *)vertexSource fragmentSource:(NSString *)fragmentSource
                  uniforms:(NSArray *)uniforms andAttributes:(NSArray *)attributes {
  if (self = [super init]) {
    self.attributes = [NSMutableDictionary dictionary];
    self.uniforms = [NSMutableDictionary dictionary];
    [self loadWithVertexSource:vertexSource fragmentSource:fragmentSource
                      uniforms:uniforms andAttributes:attributes];
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

- (void)loadWithVertexSource:(NSString *)vertexSource fragmentSource:(NSString *)fragmentSource
                    uniforms:(NSArray *)uniforms andAttributes:(NSArray *)attributes {
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
  
  // Bind attribute locations. Each attribute is bound with an index equal to its index in the input
  // array.  This needs to be done prior to linking.
  for (GLuint i = 0; i < attributes.count; ++i) {
    NSString *name = attributes[i];
    glBindAttribLocation(self.name, i, [name cStringUsingEncoding:NSASCIIStringEncoding]);
    self.attributes[name] = @(i);
  }
  
  [self linkProgram];
  
  // Get uniform locations. These are available after linking.
  for (NSString *uniformName in uniforms) {
    int uniformLocation = glGetUniformLocation(self.name, [uniformName cStringUsingEncoding:
                                                           NSASCIIStringEncoding]);
    if (uniformLocation == -1) {
      [self teardown];
      [LTGLException raise:kLTProgramUniformNotFoundException
                    format:@"Failed to retrieve uniform location for \"%@\"", uniformName];
    }
    self.uniforms[uniformName] = @(uniformLocation);
  }
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

#pragma mark -
#pragma mark Binding and unbinding
#pragma mark -

- (void)bind {
  if (self.bounded) {
    return;
  }
  glGetIntegerv(GL_CURRENT_PROGRAM, &_previousProgram);
  glUseProgram(self.name);
  self.bounded = true;
}

- (void)unbind {
  if (!self.bounded) {
    return;
  }
  glUseProgram(self.previousProgram);
  self.previousProgram = 0;
  self.bounded = YES;
}

#pragma mark -
#pragma mark Uniforms and attributes
#pragma mark -

- (GLuint)uniformForName:(NSString *)name {
  return [self.uniforms[name] unsignedIntValue];
}

- (GLuint)attributeForName:(NSString *)name {
  return [self.attributes[name] unsignedIntValue];
}

- (BOOL)containsUniform:(NSString *)name {
  return (self.uniforms[name] != nil);
}

- (BOOL)containsAttribute:(NSString *)name {
  return (self.attributes[name] != nil);
}

@end
