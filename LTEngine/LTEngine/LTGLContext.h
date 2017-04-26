// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <OpenGLES/ES2/glext.h>

#import "LTGLEnums.h"

@class LTFboPool, LTGLContext, LTProgramPool;

struct LTVector;

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

/// Supported OpenGL ES function's symbolic constants. It's used in \c depthFunc and \c stencilFunc.
typedef NS_ENUM(GLenum, LTGLFunction) {
  LTGLFunctionNever = GL_NEVER,
  LTGLFunctionLess = GL_LESS,
  LTGLFunctionLequal = GL_LEQUAL,
  LTGLFunctionEqual = GL_EQUAL,
  LTGLFunctionGreater = GL_GREATER,
  LTGLFunctionGequal = GL_GEQUAL,
  LTGLFunctionNotEqual = GL_NOTEQUAL,
  LTGLFunctionAlways = GL_ALWAYS
};

/// Mapping of the depth values from normalized device coordinates to window coordinates.
typedef struct {
  /// Mapping of the near clipping plane to window coordinates.
  GLfloat nearPlane;
  /// Mapping of the far clipping plane to window coordinates.
  GLfloat farPlane;
} LTGLDepthRange;

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
                           version:(LTGLVersion)version;

/// Executes the given block while recording changes to the state. Any change to the state inside
/// this block will be recorded and reverted after the block completes executing.
- (void)executeAndPreserveState:(NS_NOESCAPE LTGLContextBlock)execute;

/// Executes either \c openGLES2 or \c openGLES3, depending on the current API version. Both blocks
/// must not be \c nil.
- (void)executeForOpenGLES2:(NS_NOESCAPE LTVoidBlock)openGLES2
                  openGLES3:(NS_NOESCAPE LTVoidBlock)openGLES3;

/// Fills the currently bound framebuffer with the given \c colorValue and depth renderbuffer with
/// the given \c depthValue.
- (void)clearColor:(LTVector4)colorValue depth:(GLfloat)depthValue;

/// Fills all color attachables of the currently bound framebuffer with the given \c color.
- (void)clearColor:(LTVector4)color;

/// Fills the depth attachable to the currently bound framebuffer with the given \c depth.
- (void)clearDepth:(GLfloat)depth;

/// Current version of this context.
@property (readonly, nonatomic) LTGLVersion version;

/// Underlying \c EAGLContext.
@property (readonly, nonatomic) EAGLContext *context;

/// Framebuffer pool associated with this context.
@property (readonly, nonatomic) LTFboPool *fboPool;

/// Program pool associated with this context.
@property (readonly, nonatomic) LTProgramPool *programPool;

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

/// Mapping of clipping planes from normalized device coordinates to window coordinates.
/// Default values are <tt>{.nearPlane = 0, .farPlane = 1}</tt>
@property (nonatomic) LTGLDepthRange depthRange;

/// \c YES if the depth buffer is writable.
@property (nonatomic) BOOL depthMask;

/// Depth buffer comparison function.
@property (nonatomic) LTGLFunction depthFunc;

#pragma mark -
#pragma mark Capabilities
#pragma mark -

/// Maximal texture size that can be used on the device's GPU.
@property (readonly, nonatomic) GLint maxTextureSize;

/// Maximal number of texture units that can be used in the vertex and fragment shader combined on
/// the device GPU. A texture used both in the vertex and fragment shader is counted as 2 textures.
@property (readonly, nonatomic) GLint maxTextureUnits;

/// Maximal number of texture units that can be used in the fragment shader on the device GPU.
@property (readonly, nonatomic) GLint maxFragmentTextureUnits;

/// Maximum number of individual 4-vectors of floating-point, integer, or boolean values that can be
/// held in uniform variable storage by the device GPU for a vertex shader.
@property (readonly, nonatomic) GLint maxNumberOfVertexUniforms;

/// Maximum number of individual 4-vectors of floating-point, integer, or boolean values that can be
/// held in uniform variable storage by the device GPU for a fragment shader.
@property (readonly, nonatomic) GLint maxNumberOfFragmentUniforms;

/// Maximum number of color attachment points that can be used on the device's GPU.
@property (readonly, nonatomic) GLint maxNumberOfColorAttachmentPoints;

/// \c YES if rendering to half-float color buffers is supported.
@property (readonly, nonatomic) BOOL canRenderToHalfFloatColorBuffers;

/// \c YES if rednering to float color buffers is supported.
@property (readonly, nonatomic) BOOL canRenderToFloatColorBuffers;

/// \c YES if creating and rendering \c RED or \c RG textures is supported.
@property (readonly, nonatomic) BOOL supportsRGTextures;

@end
