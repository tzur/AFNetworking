// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

#import "LTBlendMode.h"
#import "LTMixerMaskMode.h"
#import "LTProcessorFillMode.h"
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

/// Initializes mixer with back and front textures, mask and an output texture. The mask must be of
/// the size of the \c front texture. The mask is applied to the front texture.
- (instancetype)initWithBack:(LTTexture *)back front:(LTTexture *)front
                        mask:(LTTexture *)mask output:(LTTexture *)output;

/// Blend mode used to blend \c front to \c back. The default value is \c LTBlendModeNormal.
@property (nonatomic) LTBlendMode blendMode;

/// How the output should be filled with the back texture. This only has effect when the size of the
/// output is different than the back texture. The default value is \c LTMixerOutputFillModeStretch.
@property (nonatomic) LTProcessorFillMode fillMode;

/// Translation of the front texture on top of the back texture. The default value is \c (0, 0).
@property (nonatomic) CGPoint frontTranslation;

/// Uniform scaling of the front texture around its center. The default value is \c 1.
@property (nonatomic) float frontScaling;

/// Rotation, in radians, of the front texture on top of the back texture. The default value is
/// \c 0.
@property (nonatomic) float frontRotation;

/// Opacity of the front texture in the range [0, 1]. Default value is \c 1.
@property (nonatomic) CGFloat frontOpacity;
LTPropertyDeclare(CGFloat, frontOpacity, FrontOpacity);

@end
