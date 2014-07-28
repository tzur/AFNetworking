// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFbo.h"

@class LTDevice, LTTexture;

/// Object for encapsulating an OpenGL framebuffer associated with an \c LTTexture, and used for
/// drawing to and reading from it. The texture is automatically locked when the block given to the
/// \c bindAndDraw is executed.
@interface LTTextureFbo : LTFbo

/// Create an FBO with a target texture (without clearing it in the process). If the given texture
/// is invalid, an \c LTGLException named \c kLTFboInvalidTextureException will be thrown.
///
/// @param texture texture to set as a render target. The texture must be of non-zero size, loaded
/// (\c name which is non-zero) and with a precision that is valid as a render target.
///
/// @note The texture will not be cleared. Use \c clear to clear the texture.
- (id)initWithTexture:(LTTexture *)texture;

// Texture backed by this framebuffer.
@property (readonly, nonatomic) LTTexture *texture;

@end

#pragma mark -
#pragma mark For testing
#pragma mark -

@interface LTFbo (ForTesting)

/// Designated initializer: create an FBO with a target texture (without clearing it in the
/// process). If the given texture is invalid, an \c LTGLException named \c
/// kLTFboInvalidTextureException will be thrown.
///
/// @param texture texture to set as a render target. The texture must be of non-zero size, loaded
/// (\c name which is non-zero) and with a precision that is valid as a render target.
/// @param device LTDevice class used to determine if the texture is legible as a render target.
///
/// @note The texture will not be cleared. Use \c clearWithColor: to clear the texture with a
/// specific color.
- (id)initWithTexture:(LTTexture *)texture device:(LTDevice *)device;

@end
