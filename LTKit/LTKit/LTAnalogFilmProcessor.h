// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTPropertyMacros.h"

@class LTColorGradient;

/// @class LTAnalogFilmProcessor
///
/// Implements analog film effect. Controls the tonal characteristics of the result and additional
/// content that makes the effect more appealing: grain, vignetting and texture.
@interface LTAnalogFilmProcessor : LTOneShotImageProcessor

/// Initializes the processor with input and output textures.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

#pragma mark -
#pragma mark Tonality
#pragma mark -

/// Changes the brightness of the image. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, brightness, Brightness);

/// Changes the global contrast of the image. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, contrast, Contrast);

/// Changes the exposure of the image. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, exposure, Exposure);

/// Changes the additive offset of the image. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, offset, Offset);

/// Increases the local contrast of the image. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, structure, Structure);

/// Changes the saturation of the image. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, saturation, Saturation);

#pragma mark -
#pragma mark Gradient
#pragma mark -

/// RGBA texture with one row and at most 256 columns that defines greyscale to color mapping.
/// This LUT is used to add tint to the image. Default value is an identity mapping.
@property (strong, nonatomic) LTTexture *colorGradientTexture;

/// Tinted result mixed with the original image according to colorGradientAlpha. Should be in [0, 1]
/// range. When 0, no tinting will occur. When 1, the result will be completely tinted. Default
/// value is 0.
LTBoundedPrimitiveProperty(CGFloat, colorGradientAlpha, ColorGradientAlpha);

#pragma mark -
#pragma mark Grain
#pragma mark -

/// Grain (noise) texture that modulates the image. Default value is a constant 0.5, which doesn't
/// affect the image.
/// @attention The texture should either have dimensions which are powers-of-2 and wrapping mode set
/// to LTTextureWrapRepeat or size of the texture should match the size of the output. This
/// restriction is enforced in order to create one-to-one mapping between the pixels of the output
/// and of the noise and thus preserve high-frequencies of the noise from interpolation smoothing.
@property (strong, nonatomic) LTTexture *grainTexture;

/// Mixes the channels of the grain texture. Default value is (1, 0, 0). Input values are
/// normalized, to remove potential interference with noise amplitude.
@property (nonatomic) GLKVector3 grainChannelMixer;

/// Amplitude of the noise. Should be in [0, 1] range. Default amplitude is 0.
LTBoundedPrimitiveProperty(CGFloat, grainAmplitude, GrainAmplitude);

#pragma mark -
#pragma mark Vignetting
#pragma mark -

/// Color of the vignetting pattern. Default color is black (0, 0, 0).
@property (nonatomic) GLKVector3 vignetteColor;

/// Percent of the image diagonal where the vignetting pattern is not zero.
/// Should be in [0-100] range. Default value is 100.
@property (nonatomic) CGFloat vignettingSpread;

/// Determines the corner type of the frame and corresponds to the p-norm which is used to compute
/// the distance field. Should be in [2-16] range.
/// Corner values determince how the distance field in the shader is created. The corner can be
/// completely round by passing 2 and creating an Euclidean distance field for increasingly higher
/// values, the distance field will become more rectangular. The limit of 16 is due to the precision
/// limits in the shader.
@property (nonatomic) CGFloat vignettingCorner;

/// Noise textures that modulates with the vignetting pattern. Default value is a constant 0.5,
/// which doesn't affect the image.
@property (strong, nonatomic) LTTexture *vignettingNoise;

/// Mixes the noise channels of the noise texture in order to create the transition noise. Default
/// value is (1, 0, 0). Input values are normalized, to remove potential interference with noise
/// amplitude.
@property (nonatomic) GLKVector3 vignettingNoiseChannelMixer;

/// Amplitude of the noise. Should be in [0, 100] range. Default amplitude is 1.
@property (nonatomic) CGFloat vignettingNoiseAmplitude;

/// Vignetting opacity. Should be in [0, 1] range. Default amplitude is 0.
LTBoundedPrimitiveProperty(CGFloat, vignettingOpacity, VignettingOpacity);

@end
