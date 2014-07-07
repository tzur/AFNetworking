// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

/// Types of blend modes that are usable in the mixer.
LTEnumDeclare(NSUInteger, LTBlendMode,
  LTBlendModeNormal,
  LTBlendModeDarken,
  LTBlendModeMultiply,
  LTBlendModeHardLight,
  LTBlendModeSoftLight,
  LTBlendModeLighten,
  LTBlendModeScreen,
  LTBlendModeColorBurn,
  LTBlendModeOverlay
);

/// How to handle the back texture if is has a different size than the output.
typedef NS_ENUM(NSUInteger, LTMixerOutputFillMode) {
  /// Stretch the back texture (possibly non-uniformly) to completely fill the output.
  LTMixerOutputFillModeStretch = 0,
  /// Tile the back texture to fill the output.
  LTMixerOutputFillModeTile
};

/// Processor for mixing two different textures, back (bottom) and front (top), with an additional
/// mask on the front texture. The back texture is fixed, while the front texture can be translated,
/// rotated and scaled. The mixer takes care of textures with alpha, and incorporates the mask's
/// alpha to the front texture while creating the blended result.
@interface LTMixerProcessor : LTOneShotImageProcessor

/// Initializes mixer with back and front textures, mask and an output texture. The mask must be of
/// the size of the \c front texture.
- (instancetype)initWithBack:(LTTexture *)back front:(LTTexture *)front
                        mask:(LTTexture *)mask output:(LTTexture *)output;

/// Blend mode used to blend \c front to \c back. The default value is \c LTBlendModeNormal.
@property (nonatomic) LTBlendMode blendMode;

/// How the output should be filled with the back texture. This only has effect when the size of the
/// output is different than the back texture. The default value is \c LTMixerOutputFillModeStretch.
@property (nonatomic) LTMixerOutputFillMode outputFillMode;

/// Translation of the front texture on top of the back texture. The default value is \c (0, 0).
@property (nonatomic) GLKVector2 frontTranslation;

/// Uniform scaling of the front texture around its center. The default value is \c 1.
@property (nonatomic) float frontScaling;

/// Rotation, in radians, of the front texture on top of the back texture. The default value is
/// \c 0.
@property (nonatomic) float frontRotation;

@end
