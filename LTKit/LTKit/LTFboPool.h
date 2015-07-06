// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@class LTFbo, LTTexture;

/// Represents a pool of OpenGL framebuffers. Framebuffers may be reused for better performance and
/// to avoid OpenGL errors.
///
/// @important this pool is not thread safe.
@interface LTFboPool : NSObject

/// Pool associated with the current \c LTGLContext or \c nil if no \c LTGLContext is associated
/// with the current thread.
+ (nullable instancetype)currentPool;

/// Returns an FBO set up with the given texture (without clearing it in the process). If the given
/// texture is invalid, an \c LTGLException named \c kLTFboInvalidTextureException will be thrown.
///
/// @param texture texture to set as a render target. The texture must be of non-zero size, loaded
/// (\c name which is non-zero) and with a precision that is valid as a render target.
///
/// @note The texture will not be cleared. Use \c clear to clear the texture.
- (LTFbo *)fboWithTexture:(LTTexture *)texture;

/// Returns an FBO set up with the target texture and mipmap level (without clearing it in the
/// process). If the given texture is invalid, an \c LTGLException named
/// \c kLTFboInvalidTextureException will be thrown.
///
/// @param texture texture to set as a render target. The texture must be of non-zero size, loaded
/// (\c name which is non-zero) and with a precision that is valid as a render target.
///
/// @param level level of the mipmap texture to set as a render target. For non mipmap textures,
/// this value must be 0, and for mipmap textures this value must be less than or equal the
/// texture's \c maxMipmapLevel.
///
/// @note The texture will not be cleared. Use \c clear to clear the texture.
- (LTFbo *)fboWithTexture:(LTTexture *)texture level:(NSUInteger)level;

@end

NS_ASSUME_NONNULL_END
