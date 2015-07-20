// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

@class LTFboPool, LTGLContext;

#import <OpenGLES/ES2/glext.h>

/// Supported OpenGL ES API versions.
typedef NS_ENUM(NSUInteger, LTGLContextAPIVersion) {
  LTGLContextAPIVersion2 = kEAGLRenderingAPIOpenGLES2,
  LTGLContextAPIVersion3 = kEAGLRenderingAPIOpenGLES3
};

/// Supported blending functions.
typedef NS_ENUM(GLenum, LTGLContextBlendFunc) {
  LTGLContextBlendFuncZero = GL_ZERO,
  LTGLContextBlendFuncOne = GL_ONE,

  LTGLContextBlendFuncSrcColor = GL_SRC_COLOR,
  LTGLContextBlendFuncOneMinusSrcColor = GL_ONE_MINUS_SRC_COLOR,
  LTGLContextBlendFuncDstColor = GL_DST_COLOR,
  LTGLContextBlendFuncOneMinusDstColor = GL_ONE_MINUS_DST_COLOR,

  LTGLContextBlendFuncSrcAlpha = GL_SRC_ALPHA,
  LTGLContextBlendFuncOneMinusSrcAlpha = GL_ONE_MINUS_SRC_ALPHA,
  LTGLContextBlendFuncDstAlpha = GL_DST_ALPHA,
  LTGLContextBlendFuncOneMinusDstAlpha = GL_ONE_MINUS_DST_ALPHA,

  LTGLContextBlendFuncAlphaSaturate = GL_SRC_ALPHA_SATURATE
};

/// Supported blending equations.
typedef NS_ENUM(GLint, LTGLContextBlendEquation) {
  LTGLContextBlendEquationAdd = GL_FUNC_ADD,
  LTGLContextBlendEquationSubtract = GL_FUNC_SUBTRACT,
  LTGLContextBlendEquationReverseSubtract = GL_FUNC_REVERSE_SUBTRACT,
  LTGLContextBlendEquationMin = GL_MIN_EXT,
  LTGLContextBlendEquationMax = GL_MAX_EXT
};

/// Set of arguments for setting the blend function.
typedef struct {
  LTGLContextBlendFunc sourceRGB;
  LTGLContextBlendFunc sourceAlpha;
  LTGLContextBlendFunc destinationRGB;
  LTGLContextBlendFunc destinationAlpha;
} LTGLContextBlendFuncArgs;

/// Set of arguments for setting the blend equation.
typedef struct {
  LTGLContextBlendEquation equationRGB;
  LTGLContextBlendEquation equationAlpha;
} LTGLContextBlendEquationArgs;

/// Block used for state-preserving execution.
typedef void (^LTGLContextBlock)(LTGLContext *context);

/// OpenGL default blend function.
extern LTGLContextBlendFuncArgs kLTGLContextBlendFuncDefault;

/// Blend function similar to Photoshop's "Normal" blend.
extern LTGLContextBlendFuncArgs kLTGLContextBlendFuncNormal;

/// OpenGL default blend equation (Additive).
extern LTGLContextBlendEquationArgs kLTGLContextBlendEquationDefault;

/// Wrapper class for \c EAGLContext, supplying abilities to set OpenGL capabilities which are not
/// specific to a single geometry or program, such as blending, depth test, face culling and more.
@interface LTGLContext : NSObject

/// Returns the current rendering context for the calling thread.
+ (LTGLContext *)currentContext;

/// Makes the specified context the current rendering context for the calling thread. If the given
/// \c context is \c nil, the rendering context will be unbound from any context.
+ (void)setCurrentContext:(LTGLContext *)context;

/// Initializes a context with a new \c EAGLContext and a new \c EAGLSharegroup. On supported
/// devices, the API version will be ES3, otherwise it will be ES2.
- (instancetype)init;

/// Initializes a context with a new \c EAGLContext and the given \c sharegroup. On supported
/// devices, the API version will be ES3, otherwise it will be ES2.
- (instancetype)initWithSharegroup:(EAGLSharegroup *)sharegroup;

/// Initializes a context with a new \c EAGLContext of version \c version using the given \c
/// sharegroup. If \c version is not supported, this initializer will return \c nil.
- (instancetype)initWithSharegroup:(EAGLSharegroup *)sharegroup
                           version:(LTGLContextAPIVersion)version;

/// Executes the given block while recording changes to the state. Any change to the state inside
/// this block will be recorded and reverted after the block completes executing.
- (void)executeAndPreserveState:(LTGLContextBlock)execute;

/// Executes either \c openGLES2 or \c openGLES3, depending on the current API version. Both blocks
/// must not be \c nil.
- (void)executeForOpenGLES2:(LTVoidBlock)openGLES2 openGLES3:(LTVoidBlock)openGLES3;

/// Fills the currently bound framebuffer with the given color.
- (void)clearWithColor:(LTVector4)color;

/// Current version of this context.
@property (readonly, nonatomic) LTGLContextAPIVersion version;

/// Underlying \c EAGLContext.
@property (readonly, nonatomic) EAGLContext *context;

/// Framebuffer pool associated with this context.
@property (readonly, nonatomic) LTFboPool *fboPool;

/// Blend function.
@property (nonatomic) LTGLContextBlendFuncArgs blendFunc;

/// Blend equation.
@property (nonatomic) LTGLContextBlendEquationArgs blendEquation;

/// Scissor box, in pixels. Non-integer values will be rounded to the nearest integer.
@property (nonatomic) CGRect scissorBox;

/// \c YES if the currently bound framebuffer is a screen framebuffer.
@property (nonatomic) BOOL renderingToScreen;

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

/// \c YES if a clockwise drawn polygon is front facing, \c NO if a counter-clockwise one is.
@property (nonatomic) BOOL clockwiseFrontFacingPolygons;

/// Alignment requirements for start of each pixel in memory, when reading data from OpenGL.
/// Allowed values are {1, 2, 4, 8}.
@property (nonatomic) GLint packAlignment;

/// Alignment requirements for start of each pixel in memory, when writing data to OpenGL.
/// Allowed values are {1, 2, 4, 8}.
@property (nonatomic) GLint unpackAlignment;

@end
