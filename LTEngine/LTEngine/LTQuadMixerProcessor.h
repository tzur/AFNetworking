// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTOneShotImageProcessor.h"

#import "LTBlendMode.h"
#import "LTMixerMaskMode.h"
#import "LTPropertyMacros.h"

@class LTQuad;

/// Processor for mixing two different textures, back (bottom) and front (top), with an additional
/// mask on the front (default) or back texture. The back texture is fixed and is rendered onto the
/// output texture, possibly stretching it, while the front texture is defined by a quad in the
/// coordinate system of the output texture. The transformation of the mask texture corresponds to
/// the transformation of the associated texture (front or back). The mixer takes care of textures
/// with alpha, and incorporates the mask's alpha to the front texture while creating the blended
/// result.
@interface LTQuadMixerProcessor : LTOneShotImageProcessor

/// Initializes mixer with \c back and \c front textures, \c mask and an \c output texture. The mask
/// must be of the size of the \c front texture if \c maskMode is \c LTMixerMaskModeFront, and of
/// the size of the \c back texture if \c maskMode is \c LTMixerMaskModeBack. If \c back is
/// identical to \c output, the last fragment shader data is used rather than accessing the back
/// texture.
- (instancetype)initWithBack:(LTTexture *)back front:(LTTexture *)front mask:(LTTexture *)mask
                      output:(LTTexture *)output maskMode:(LTMixerMaskMode)maskMode;

/// Blend mode used to blend \c front to \c back. The default value is \c LTBlendModeNormal.
@property (nonatomic) LTBlendMode blendMode;

/// Quad, in coordinate system of the \c output texture, into which the \c front texture is drawn.
@property (strong, nonatomic) LTQuad *frontQuad;

/// Opacity of the \c front texture in the range [0, 1]. Default value is \c 1.
@property (nonatomic) CGFloat frontOpacity;
LTPropertyDeclare(CGFloat, frontOpacity, FrontOpacity);

@end
