// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTexture.h"

/// An FBO class to manage drawing openGL content directly to a texture.
/// Initialize this class with the desired texture. call \c bind to bind the framebuffer, following
/// by your standard opengl drawing code. finish with unbind to rebind the previous framebuffer (or
/// to another \c LTFbo instance).
///
/// Usage example: (all these must run from the UI thread)
/// @code
/// // Draw something into a texture.
/// LTFbo *fbo = [[LTFbo alloc] initWithTexture:texture];
/// [fbo bind]
/// glClear();
/// drawSomething();
/// [fbo unbind]
///
/// // Use this texture in your shader.
/// glActiveTexture(GL_TEXTURE0);
/// glBindTexture(GL_TEXTURE_2D, fbo.glName);
/// glUniform1i(myShader[@"myuniform"], 0);
/// @endcode

@interface LTFbo : NSObject

/// Designated initializer: initialize an fbo with the given texture (without clearing it in the
/// process).
///
/// @returns nil in case the texture is nil, its glName is zero, if the precision type of the
/// texture is not supported by the device, or if an error occured while trying to create the
/// framebuffer.
/// precision type (
/// the process. Exception will be thrown if the texture is nil, its glName is nil or a
/// texture with an unsupported precision type (by the device) is given. Using textures with
/// LTTexturePrecisionByte is supported on all devices, while LTTexturePrecisionHalfFloat is
/// supported on iPad2/iPhone4S and later. LTTexturePrecisionFloat is not supported. In case of an
/// error while initializing the texture, the kLTOutOfMemoryNotification notification will be sent on
/// memory errors. In other cases, an exception will be thrown describing the error encountered.
- (id)initWithTexture:(LTTexture *)texture;

/// Binds the framebuffer. Everything that will be drawn between this call and the call to unbind
/// will be saved on the fbo texture. The previously bound framebuffer and viewport will be
/// saved, so they can be restored when unbind is called.
- (void)bind;

/// Unbinds the framebuffer, so future drawing calls will no longer affect the fbo's texture.
///
- (void)unbind;

// Unbinds the framebuffer and binds the
/// If another fbo is given, this method will configure its previously bound framebuffer and
/// viewport and call it's bind method.
- (void)unbindToAnotherFbo:(LTFbo *)fbo;

/// Returns the openGL identifier of the texture associated with this Fbo.
@property (readonly, nonatomic) GLuint name;
/// Returns the size of the texture associated with this Fbo.
@property (readonly, nonatomic) CGSize size;

@end
