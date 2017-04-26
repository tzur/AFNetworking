// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFboAttachable.h"
#import "LTGPUResource.h"

NS_ASSUME_NONNULL_BEGIN

@class LTFboAttachmentInfo, LTGLContext, LTGLPixelFormat, LTRenderbuffer, LTTexture;

/// Framebuffer's attachment points.
typedef NS_ENUM(GLenum, LTFboAttachmentPoint) {
  /// Color attachment points.
  LTFboAttachmentPointColor0 = GL_COLOR_ATTACHMENT0,
  LTFboAttachmentPointColor1 = GL_COLOR_ATTACHMENT1,
  LTFboAttachmentPointColor2 = GL_COLOR_ATTACHMENT2,
  LTFboAttachmentPointColor3 = GL_COLOR_ATTACHMENT3,
  /// Depth attachment point.
  LTFboAttachmentPointDepth = GL_DEPTH_ATTACHMENT,
};

/// Object for encapsulating an OpenGL framebuffer, used for drawing to and reading from multiple
/// attachables. Attachable could be either a Renderbuffer or a 2D Texture.
///
/// @note for \c size, \c attachable, \c pixelFormat and \c level properties the queried
/// attachable is first attachable in following order: \c LTFboAttachmentPointColorN
/// (\c N is in <tt>{0, 1, ...}<\tt>), \c LTFboAttachmentPointDepth.
///
/// @note \c LTGLPixelFormatDepth16Unorm is the only pixel format supported for the
/// \c LTFboAttachable of type \c LTFboAttachableTypeTexture2D attached at
/// \c LTFboAttachmentPointDepth.
@interface LTFbo : NSObject <LTGPUResource>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given non empty \c infos, which maps \c LTFboAttachmentPoint to
/// \c LTFboAttachmentInfo.
- (instancetype)initWithAttachmentInfos:(NSDictionary<NSNumber *, LTFboAttachmentInfo *> *)infos;

/// Initializes with the given non empty \c attachables, which maps \c LTFboAttachmentPoint
/// to \c LTFboAttachmentPoint. All \c attachables will be attached with \c level set to \c 0.
- (instancetype)initWithAttachables:(NSDictionary<NSNumber *, id<LTFboAttachable>> *)attachables;

/// Creates an FBO with the given \c texture as an attachable. The texture is not cleared in the
/// process. If the given texture is invalid, an \c LTGLException named
/// \c kLTFboInvalidAttachmentException will be thrown.
///
/// @param texture texture to set as an attachable. The texture must be of non-zero size, loaded
/// (\c name which is non-zero) and with a precision that is valid as a attachable.
///
/// @note The texture will not be cleared. Use \c clear to clear the texture.
- (instancetype)initWithTexture:(LTTexture *)texture;

/// Creates an FBO with the given \c texture and a mipmap level as an attachable. The texture is not
/// cleared in the process. If the given texture is invalid, an \c LTGLException named
/// \c kLTFboInvalidAttachmentException will be thrown.
///
/// @param texture texture to set as an attachable. The texture must be of non-zero size, loaded
/// (\c name which is non-zero) and with a precision that is valid as a attachable.
///
/// @param level level of the mipmap texture to set as a render target. For non mipmap textures,
/// this value must be 0, and for mipmap textures this value must be less than or equal the
/// texture's \c maxMipmapLevel.
///
/// @note The texture will not be cleared. Use \c clear to clear the texture.
- (instancetype)initWithTexture:(LTTexture *)texture level:(GLint)level;

/// Creates an FBO with a target renderbuffer. If the given renderbuffer is invalid, an
/// \c LTGLException named \c kLTFboInvalidAttachmentException will be thrown.
///
/// @param renderbuffer renderbuffer to set as an attachable. The renderbuffer must be of non-zero
/// size and valid \c name which is non-zero.
- (instancetype)initWithRenderbuffer:(LTRenderbuffer *)renderbuffer;

/// Executes the given block while the receiver is bound to the active context, while locking the
/// framebuffer's attachable when the block is executed. If the receiver is not already bound, this
/// will automatically \c bind and \c unbind the receiver before and after the block, accordingly.
/// If the receiver is bound, the block will execute, but no binding and unbinding will be executed.
/// Making recursive calls to \c bindAndDraw: is possible without loss of context.
///
/// @note use this method when drawing into the framebuffer's attachable, instead of
/// \c bindAndExecute:.
///
/// @param block The block to execute after binding the resource. This parameter cannot be nil.
- (void)bindAndDraw:(NS_NOESCAPE LTVoidBlock)block;

/// Fills all color attachables bound to this FBO with the given color.
- (void)clearColor:(LTVector4)color;

/// Fills the attachable attached to \c LTFboAttachmentPointDepth (if exists) with the given
/// \c value. If there's no depth attachable attached, this method has no effect.
- (void)clearDepth:(GLfloat)value;

/// Size of the attachable associated with this framebuffer. Attachable selection policy is
/// described in this class documentation.
@property (readonly, nonatomic) CGSize size;

/// Attachable associated with the framebuffer. Attachable selection policy is described in this
/// class documentation.
@property (readonly, nonatomic) id<LTFboAttachable> attachment;

/// Pixel format of the attachable associated with this framebuffer. Attachable selection policy is
/// described in this class documentation.
@property (readonly, nonatomic) LTGLPixelFormat *pixelFormat;

/// Mipmap level of the the attachable bound to the FBO. In case the attachable is not a mipmap
/// texture, the value will be \c 0. Attachable selection policy is described in this class
/// documentation.
@property (readonly, nonatomic) GLint level;

@end

#pragma mark -
#pragma mark For testing
#pragma mark -

@interface LTFbo (ForTesting)

/// Creates an FBO with a target texture (without clearing it in the process). If the given texture
/// is invalid, an \c LTGLException named \c kLTFboInvalidAttachmentException will be thrown.
///
/// @param texture texture to set as a render target. The texture must be of non-zero size, loaded
/// (\c name which is non-zero) and with a precision that is valid as a render target.
/// @param context LTGLContext class used to determine if the texture is legible as a render target.
///
/// @note The texture will not be cleared. Use \c clearWithColor: to clear the texture with a
/// specific color.
- (instancetype)initWithTexture:(LTTexture *)texture context:(LTGLContext *)context;

/// Initializes with the given \c context and the given non empty \c infos, which maps
/// \c LTFboAttachmentPoint to \c LTFboAttachmentInfo.
- (instancetype)initWithContext:(LTGLContext *)context
                attachmentInfos:(NSDictionary<NSNumber *, LTFboAttachmentInfo *> *)infos;

/// Executes the given block while the receiver is bound to the active context, and \c LTGLContext's
/// \c renderingToScreen is set to YES.
- (void)bindAndDrawOnScreen:(NS_NOESCAPE LTVoidBlock)block;

@end

NS_ASSUME_NONNULL_END
