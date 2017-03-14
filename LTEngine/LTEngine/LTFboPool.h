// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@class LTFbo, LTRenderbuffer, LTTexture;

/// Represents a pool of OpenGL framebuffers. Framebuffers may be reused for better performance and
/// to avoid OpenGL errors.
///
/// @important this pool is not thread safe.
@interface LTFboPool : NSObject

/// Pool associated with the current \c LTGLContext or \c nil if no \c LTGLContext is associated
/// with the current thread.
+ (nullable instancetype)currentPool;

/// Returns an FBO with the given \c texture as an attachment. The texture is not cleared in the
/// process. If the given texture is invalid, an \c LTGLException named
/// \c kLTFboInvalidAttachmentException will be thrown.
///
/// @param texture texture to set as an attachment. The texture must be of non-zero size, loaded
/// (\c name which is non-zero) and with a precision that is valid as a attachment.
///
/// @note The texture will not be cleared. Use \c clear to clear the texture.
- (LTFbo *)fboWithTexture:(LTTexture *)texture;

/// Returns an FBO with the given \c texture and a mipmap level as an attachment. The texture is not
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
- (LTFbo *)fboWithTexture:(LTTexture *)texture level:(NSUInteger)level;

/// Returns an FBO with a target renderbuffer. If the given renderbuffer is invalid, an
/// \c LTGLException named \c kLTFboInvalidAttachmentException will be thrown.
///
/// @param renderbuffer renderbuffer to set as an attachment. The renderbuffer must be of non-zero
/// size and valid \c name which is non-zero.
- (LTFbo *)fboWithRenderbuffer:(LTRenderbuffer *)renderbuffer;

@end

NS_ASSUME_NONNULL_END
