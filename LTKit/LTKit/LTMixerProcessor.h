// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

#import "LTBlendMode.h"
#import "LTMixerMaskMode.h"
#import "LTPropertyMacros.h"

/// Processor for mixing two different textures, back (bottom) and front (top), with an additional
/// mask on the front (default) or back texture. The back texture is fixed, while the front texture
/// can be translated, rotated and scaled. The transformation of the mask texture corresponds to the
/// transformation of the associated texture. The mixer takes care of textures with alpha, and
/// incorporates the mask's alpha to the front texture while creating the blended result.
@interface LTMixerProcessor : LTOneShotImageProcessor

/// Initializes mixer with back and front textures, mask and an output texture. The mask must be of
/// the size of the \c front texture if \c maskMode is \c LTMixerMaskModeFront, and of the size of
/// the \c back texture if \c maskMode is \c LTMixerMaskModeBack.
- (instancetype)initWithBack:(LTTexture *)back front:(LTTexture *)front mask:(LTTexture *)mask
                      output:(LTTexture *)output maskMode:(LTMixerMaskMode)maskMode;

/// Initializes mixer with \c back and \c front textures, \c mask and \c output texture. The \c mask
/// must be of the size of the \c front texture, while the \c back must be of the size of the
/// \c output. The mask is applied to the front texture.
- (instancetype)initWithBack:(LTTexture *)back front:(LTTexture *)front mask:(LTTexture *)mask
                      output:(LTTexture *)output;

/// Blend mode used to blend \c front to \c back. The default value is \c LTBlendModeNormal.
@property (nonatomic) LTBlendMode blendMode;

/// Default front translation value (\c (0, 0)).
@property (readonly, nonatomic) CGPoint defaultFrontTranslation;

/// Translation of the front texture on top of the back texture. The default value is \c (0, 0).
@property (nonatomic) CGPoint frontTranslation;

/// Default front scaling value (\c 1).
@property (readonly, nonatomic) float defaultFrontScaling;

/// Uniform scaling of the front texture around its center. The default value is \c 1.
@property (nonatomic) float frontScaling;

/// Default front rotation value (\c 0).
@property (readonly, nonatomic) float defaultFrontRotation;

/// Rotation, in radians, of the front texture on top of the back texture. The default value is
/// \c 0.
@property (nonatomic) float frontRotation;

/// Opacity of the front texture in the range [0, 1]. Default value is \c 1.
@property (nonatomic) CGFloat frontOpacity;
LTPropertyDeclare(CGFloat, frontOpacity, FrontOpacity);

@end
