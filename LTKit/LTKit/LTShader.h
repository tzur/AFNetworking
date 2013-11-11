// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTProgram.h"

/// Type of shaders.
typedef NS_ENUM(NSUInteger, LTShaderType) {
  LTShaderTypeVertex = GL_VERTEX_SHADER,
  LTShaderTypeFragment = GL_FRAGMENT_SHADER
};

/// @class LTShader
/// Represents an OpenGL shader. The shader is a part of a program, which usually consists of a
/// vertex shader and a fragment shader. See the Program class for more information.
@interface LTShader : NSObject

/// Constructs a shader with its source and type. Compiles the given shader source. If the shader
/// did not compile successfully, an exception will be thrown.
///
/// Throws \c LTGLexception with \c kLTShaderCreationFailedException if the shader failed to create
/// or \c kLTShaderCompilationFailedException if the shader failed to compile.
- (id)initWithType:(LTShaderType)type andSource:(NSString *)source;

/// Binds the shader to the given program name. If shader is already bounded, the call is ignored.
- (void)bindToProgram:(LTProgram *)program;

/// Unbinds the shader from the bounded program. If the shader is not bounded, the call is ignored.
- (void)unbind;

/// Type of the shader.
@property (readonly, nonatomic) LTShaderType type;

/// Name of the shader.
@property (readonly, nonatomic) GLuint name;

@end
