// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTProgram.h"
#import "LTTypedefs.h"

/// Type of shaders.
typedef NS_ENUM(NSUInteger, LTShaderType) {
  LTShaderTypeVertex = GL_VERTEX_SHADER,
  LTShaderTypeFragment = GL_FRAGMENT_SHADER
};

/// @class LTShader
///
/// Represents an OpenGL shader. The shader is a part of a program, which usually consists of a
/// vertex shader and a fragment shader. See the Program class for more information.
@interface LTShader : NSObject

/// Constructs a shader with its source and type. Compiles the given shader source. If the shader
/// did not compile successfully, an exception will be thrown.
///
/// Throws \c LTGLexception with \c kLTShaderCreationFailedException if the shader failed to create
/// or \c kLTShaderCompilationFailedException if the shader failed to compile.
- (instancetype)initWithType:(LTShaderType)type andSource:(NSString *)source;

/// Attaches the shader to the given program name. If shader is already attached to a program, the
/// call is ignored.
- (void)attachToProgram:(LTProgram *)program;

/// Detaches the shader from the attached program. If the shader is not bound, the call is ignored.
- (void)detach;

/// Attaches to the given program, executes the block and detaches afterwards. Making recursive
/// calls to \c attachToProgram:andExecute: is possible without loss of context.
- (void)attachToProgram:(LTProgram *)program andExecute:(LTVoidBlock)block;

/// Type of the shader.
@property (readonly, nonatomic) LTShaderType type;

/// Name of the shader.
@property (readonly, nonatomic) GLuint name;

@end
