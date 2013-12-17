// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTexture.h"

#import "LTGPUResource.h"

@class LTDevice;

/// @class LTFbo
///
/// Object for encapsulating an OpenGL framebuffer, used for drawing to a texture and reading from
/// it.
@interface LTFbo : NSObject <LTGPUResource>

/// Create an FBO with a target texture (without clearing it in the process). If the given texture
/// is invalid, an \c LTGLException named \c kLTFboInvalidTextureException will be thrown.
///
/// @param texture texture to set as a render target. The texture must be of non-zero size, loaded
/// (\c name which is non-zero) and with a precision that is valid as a render target.
///
/// @note The texture will not be cleared. Use \c clear to clear the texture.
- (id)initWithTexture:(LTTexture *)texture;

/// Binds the framebuffer. Everything that will be drawn between this call and the call to unbind
/// will be saved to the texture. The previously bound framebuffer and viewport will be
/// saved, so they can be restored when unbind is called. Consecutive calls to \c bind while the
/// receiver is already bound will have no effect.
- (void)bind;

/// Unbinds the framebuffer. Consecutive calls to \c bind while the receiver is already bound will
/// have no effect.
- (void)unbind;

/// Fills the texture bound to this FBO with the given color.
- (void)clearWithColor:(GLKVector4)color;

/// Returns the best supported target texture precision for the given source precision. For example,
/// on some devices it's possible to create float or half-float textures using the \c
/// texture_float and \c texture_half_float extensions, but the \c color_buffer_float and \c
/// color_buffer_half_float extensions may be absent, limiting the possibility to render with the
/// same precision. This method will return the best precision supported on this device that also
/// best matches the given source precision.
+ (LTTexturePrecision)bestTargetPrecisionForSourcePrecision:(LTTexturePrecision)precision;

/// Size of the texture associated with this framebuffer.
@property (readonly, nonatomic) CGSize size;

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
