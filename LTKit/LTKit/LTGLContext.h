// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Supported blending functions.
typedef NS_ENUM(GLenum, LTGLStateBlendFunc) {
  LTGLStateBlendFuncZero = GL_ZERO,
  LTGLStateBlendFuncOne = GL_ONE,

  LTGLStateBlendFuncSrcColor = GL_SRC_COLOR,
  LTGLStateBlendFuncOneMinusSrcColor = GL_ONE_MINUS_SRC_COLOR,
  LTGLStateBlendFuncDstColor = GL_DST_COLOR,
  LTGLStateBlendFuncOneMinusDstColor = GL_ONE_MINUS_DST_COLOR,

  LTGLStateBlendFuncSrcAlpha = GL_SRC_ALPHA,
  LTGLStateBlendFuncOneMinusSrcAlpha = GL_ONE_MINUS_SRC_ALPHA,
  LTGLStateBlendFuncDstAlpha = GL_DST_ALPHA,
  LTGLStateBlendFuncOneMinusDstAlpha = GL_ONE_MINUS_DST_ALPHA,

  LTGLStateBlendFuncAlphaSaturate = GL_SRC_ALPHA_SATURATE
};

/// Supported blending equations.
typedef NS_ENUM(GLint, LTGLStateBlendEquation) {
  LTGLStateBlendEquationAdd = GL_FUNC_ADD,
  LTGLStateBlendEquationSubtract = GL_FUNC_SUBTRACT,
  LTGLStateBlendEquationReverseSubtract = GL_FUNC_REVERSE_SUBTRACT,
  LTGLStateBlendEquationMin = GL_MIN_EXT,
  LTGLStateBlendEquationMax = GL_MAX_EXT
};

/// @class LTGLContext
///
/// Wrapper class for \c EAGLContext, supplying abilities to set OpenGL capabilities which are not
/// specific to a single geometry or program, such as blending, depth test, face culling and more.
@interface LTGLContext : NSObject

/// Initializes the context with a new underlying \c EAGLContext and sets it as the current context.
- (instancetype)init;

/// Designated initializer: initiailizes the context with an existing OpenGL context and sets it as
/// the current context.
- (instancetype)initWithContext:(EAGLContext *)context;

/// Executes the given block while recording changes to the state. Any change to the state inside
/// this block will be recorded and reverted after the block completes executing.
- (void)executeAndPreserveState:(LTVoidBlock)execute;

/// Sets the current context as the active context for the calling thread.
- (void)setAsCurrentContext;

/// Underlying \c EAGLContext.
@property (readonly, nonatomic) EAGLContext *context;

/// Source RGB blend function.
@property (nonatomic) LTGLStateBlendFunc blendFuncSourceRGB;

/// Destination RGB blend function.
@property (nonatomic) LTGLStateBlendFunc blendFuncDestinationRGB;

/// Source alpha blend function.
@property (nonatomic) LTGLStateBlendFunc blendFuncSourceAlpha;

/// Destination alpha blend function.
@property (nonatomic) LTGLStateBlendFunc blendFuncDestinationAlpha;

/// Equation used for the RGB term.
@property (nonatomic) LTGLStateBlendEquation blendEquationRGB;

/// Equation used for the alpha term.
@property (nonatomic) LTGLStateBlendEquation blendEquationAlpha;

/// \c YES if blending is enabled.
@property (nonatomic) BOOL blendEnabled;

/// \c YES if face culling is enabled.
@property (nonatomic) BOOL faceCullingEnabled;

/// \c YES if depth test is enabled.
@property (nonatomic) BOOL depthTestEnabled;

/// \c YES if scissor test is enabled.
@property (nonatomic) BOOL scissorTestEnabled;

/// \c YES if stencil test is enabled.
@property (nonatomic) BOOL stencilTestEnabled;

/// \c YES if dithering is enabled.
@property (nonatomic) BOOL ditheringEnabled;

@end
