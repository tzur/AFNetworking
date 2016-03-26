// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFboAttachment.h"
#import "LTGPUResource.h"

@class LTGLContext, LTGLPixelFormat, LTRenderbuffer, LTTexture;

/// Object for encapsulating an OpenGL framebuffer, used for drawing to and reading from an
/// attachment, which could be either a Renderbuffer or a 2D Texture.
@interface LTFbo : NSObject <LTGPUResource>

/// Creates an FBO with the given \c texture as an attachment. The texture is not cleared in the
/// process. If the given texture is invalid, an \c LTGLException named
/// \c kLTFboInvalidAttachmentException will be thrown.
///
/// @param texture texture to set as an attachment. The texture must be of non-zero size, loaded
/// (\c name which is non-zero) and with a precision that is valid as a attachment.
///
/// @note The texture will not be cleared. Use \c clear to clear the texture.
- (instancetype)initWithTexture:(LTTexture *)texture;

/// Creates an FBO with the given \c texture and a mipmap level as an attachment. The texture is not
/// cleared in the process. If the given texture is invalid, an \c LTGLException named
/// \c kLTFboInvalidAttachmentException will be thrown.
///
/// @param texture texture to set as an attachment. The texture must be of non-zero size, loaded
/// (\c name which is non-zero) and with a precision that is valid as a attachment.
///
/// @param level level of the mipmap texture to set as a render target. For non mipmap textures,
/// this value must be 0, and for mipmap textures this value must be less than or equal the
/// texture's \c maxMipmapLevel.
///
/// @note The texture will not be cleared. Use \c clear to clear the texture.
- (instancetype)initWithTexture:(LTTexture *)texture level:(NSUInteger)level;

/// Creates an FBO with a target renderbuffer. If the given renderbuffer is invalid, an
/// \c LTGLException named \c kLTFboInvalidAttachmentException will be thrown.
///
/// @param renderbuffer renderbuffer to set as an attachment. The renderbuffer must be of non-zero
/// size and valid \c name which is non-zero.
- (instancetype)initWithRenderbuffer:(LTRenderbuffer *)renderbuffer;

/// Executes the given block while the receiver is bound to the active context, while locking the
/// framebuffer's attachment when the block is executed. If the receiver is not already bound, this
/// will automatically \c bind and \c unbind the receiver before and after the block, accordingly.
/// If the receiver is bound, the block will execute, but no binding and unbinding will be executed.
/// Making recursive calls to \c bindAndDraw: is possible without loss of context.
///
/// @note use this method when drawing into the framebuffer's attachment, instead of
/// \c bindAndExecute:.
///
/// @param block The block to execute after binding the resource. This parameter cannot be nil.
- (void)bindAndDraw:(LTVoidBlock)block;

/// Fills the attachment bound to this FBO with the given color.
- (void)clearWithColor:(LTVector4)color;

/// Size of the attachment associated with this framebuffer.
@property (readonly, nonatomic) CGSize size;

/// Attachment associated with the framebuffer.
@property (readonly, nonatomic) id<LTFboAttachment> attachment;

/// Pixel format of the attachment associated with this framebuffer.
@property (readonly, nonatomic) LTGLPixelFormat *pixelFormat;

/// Mipmap level of the the attachment bound to the FBO. In case the attachment is not a mipmap
/// texture, the value will be \c 0.
@property (readonly, nonatomic) GLint level;

@end

#pragma mark -
#pragma mark For testing
#pragma mark -

@interface LTFbo (ForTesting)

/// Designated initializer: create an FBO with a target texture (without clearing it in the
/// process). If the given texture is invalid, an \c LTGLException named \c
/// kLTFboInvalidAttachmentException will be thrown.
///
/// @param texture texture to set as a render target. The texture must be of non-zero size, loaded
/// (\c name which is non-zero) and with a precision that is valid as a render target.
/// @param context LTGLContext class used to determine if the texture is legible as a render target.
///
/// @note The texture will not be cleared. Use \c clearWithColor: to clear the texture with a
/// specific color.
- (instancetype)initWithTexture:(LTTexture *)texture context:(LTGLContext *)context;

/// Executes the given block while the receiver is bound to the active context, and \c LTGLContext's
/// \c renderingToScreen is set to YES. 
- (void)bindAndDrawOnScreen:(LTVoidBlock)block;

@end
