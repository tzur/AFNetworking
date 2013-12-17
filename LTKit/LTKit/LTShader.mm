// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTShader.h"

#import "LTGLException.h"

@interface LTShader ()

/// Type of the shader.
@property (readwrite, nonatomic) LTShaderType type;

/// Name of the shader.
@property (readwrite, nonatomic) GLuint name;

/// The bound program or nil if not bound.
@property (strong, nonatomic) LTProgram *boundProgram;

@end

@implementation LTShader

#pragma mark -
#pragma mark Initialization and destruction
#pragma mark -

- (id)initWithType:(LTShaderType)type andSource:(NSString *)source {
  if (self = [super init]) {
    self.type = type;
    [self compileSource:source];
  }
  return self;
}

- (void)dealloc {
  [self detach];

  glDeleteShader(_name);
  LTGLCheckDbg(@"Error deleting shader");
}

#pragma mark -
#pragma mark Utility methods
#pragma mark -

- (void)compileSource:(NSString *)source {
  self.name = glCreateShader(self.type);
  LTGLCheck(@"Shader creation failed");
  
  const char *cSource = [source cStringUsingEncoding:NSUTF8StringEncoding];
  glShaderSource(self.name, 1, &cSource, NULL);
  glCompileShader(self.name);
  
#ifdef DEBUG
  GLint logLength;
  glGetShaderiv(self.name, GL_INFO_LOG_LENGTH, &logLength);
  if (logLength > 0) {
    std::unique_ptr<GLchar[]> log(new GLchar[logLength]);
    glGetShaderInfoLog(self.name, logLength, NULL, log.get());
    [LTGLException raise:kLTShaderCompilationFailedException
                  format:@"Failed compiling shader: log: %s, type: %d, source: %@",
                         log.get(), (int)self.type, source];
  }
#endif
  
  GLint status;
  glGetShaderiv(self.name, GL_COMPILE_STATUS, &status);
  if (status == GL_FALSE) {
    [LTGLException raise:kLTShaderCompilationFailedException
                  format:@"Failed compiling shader: type: %d, source: %@", (int)self.type, source];
  }
}

#pragma mark -
#pragma mark Attaching
#pragma mark -

- (void)attachToProgram:(LTProgram *)program {
  if (self.boundProgram) {
    return;
  }
  glAttachShader(program.name, self.name);
  self.boundProgram = program;
}

- (void)detach {
  if (!self.boundProgram) {
    return;
  }
  glDetachShader(self.boundProgram.name, self.name);
  self.boundProgram = nil;
}

- (void)attachToProgram:(LTProgram *)program andExecute:(LTVoidBlock)block {
  if (self.boundProgram) {
    if (block) block();
  } else {
    [self attachToProgram:program];
    if (block) block();
    [self detach];
  }
}

@end
