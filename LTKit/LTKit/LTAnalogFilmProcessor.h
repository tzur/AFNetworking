// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTPropertyMacros.h"

@class LTColorGradient;

/// Types of blend modes that can be used to blend the color gradient with the image.
typedef NS_ENUM(NSUInteger, LTAnalogBlendMode) {
  LTAnalogBlendModeNormal = 0,
  LTAnalogBlendModeDarken,
  LTAnalogBlendModeMultiply,
  LTAnalogBlendModeHardLight,
  LTAnalogBlendModeSoftLight,
  LTAnalogBlendModeLighten,
  LTAnalogBlendModeScreen,
  LTAnalogBlendModeColorBurn,
  LTAnalogBlendModeOverlay
};

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
@property (nonatomic) CGFloat brightness;
LTPropertyDeclare(CGFloat, brightness, Brightness);

/// Changes the global contrast of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat contrast;
LTPropertyDeclare(CGFloat, contrast, Contrast);

/// Changes the exposure of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat exposure;
LTPropertyDeclare(CGFloat, exposure, Exposure);

/// Changes the additive offset of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat offset;
LTPropertyDeclare(CGFloat, offset, Offset);

/// Increases the local contrast of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat structure;
LTPropertyDeclare(CGFloat, structure, Structure);

/// Changes the saturation of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat saturation;
LTPropertyDeclare(CGFloat, saturation, Saturation);

#pragma mark -
#pragma mark Gradient
#pragma mark -

/// RGBA texture with one row and at most 256 columns that defines greyscale to color mapping.
/// This LUT is used to add tint to the image. Default value is an identity mapping. Setting this
/// property to \c nil will restore the default value.
@property (strong, nonatomic) LTTexture *colorGradientTexture;

/// Blend mode used to blend tinted image with the processed original image. Tinted image is the
/// front and processed original image is the back. The default value is \c LTBlendModeNormal.
@property (nonatomic) LTAnalogBlendMode blendMode;

/// Tinted result mixed with the original image according to colorGradientAlpha. Should be in [0, 1]
/// range. When 0, no tinting will occur. When 1, the result will be completely tinted. Default
/// value is 0.
@property (nonatomic) CGFloat colorGradientAlpha;
LTPropertyDeclare(CGFloat, colorGradientAlpha, ColorGradientAlpha);

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

/// Mixes the channels of the grain texture. Default value is (1, 0, 0). Components should be in
/// [0, 1] range. Input values are normalized, to remove potential interference with noise
/// amplitude.
@property (nonatomic) LTVector3 grainChannelMixer;
LTPropertyDeclare(LTVector3, grainChannelMixer, GrainChannelMixer);

/// Amplitude of the noise. Should be in [0, 1] range. Default amplitude is 0.
@property (nonatomic) CGFloat grainAmplitude;
LTPropertyDeclare(CGFloat, grainAmplitude, GrainAmplitude);

#pragma mark -
#pragma mark Vignetting
#pragma mark -

/// Color of the vignetting pattern. Color components should be in [0, 1] range. Default color is
/// black (0, 0, 0).
@property (nonatomic) LTVector3 vignetteColor;
LTPropertyDeclare(LTVector3, vignetteColor, VignetteColor);

/// Percent of the image diagonal where the vignetting pattern is not zero.
/// Should be in [0-100] range. Default value is 0.
@property (nonatomic) CGFloat vignetteSpread;
LTPropertyDeclare(CGFloat, vignetteSpread, VignetteSpread);

/// Determines the corner type of the frame and corresponds to the p-norm which is used to compute
/// the distance field. Should be in [2-16] range. The default value is 2.
/// Corner values determince how the distance field in the shader is created. The corner can be
/// completely round by passing 2 and creating an Euclidean distance field for increasingly higher
/// values, the distance field will become more rectangular. The limit of 16 is due to the precision
/// limits in the shader.
@property (nonatomic) CGFloat vignetteCorner;
LTPropertyDeclare(CGFloat, vignetteCorner, VignetteCorner);

/// Noise textures that modulates with the vignetting pattern. Default value is a constant 0.5,
/// which doesn't affect the image. Set \c noise back to \c nil to restore the default value.
///
/// @attention Noise is assumed to be with 0.5 mean. Stick to this assumption, unless you want to
/// create a very specific visual result and understand well the underlying frame creation process.
@property (strong, nonatomic) LTTexture *vignetteNoise;

/// Mixes the noise channels of the noise texture in order to create the transition noise.
/// Components should be in [0, 1] range. Default value is (1, 0, 0). Input values are normalized,
/// to remove potential interference with noise amplitude.
@property (nonatomic) LTVector3 vignetteNoiseChannelMixer;
LTPropertyDeclare(LTVector3, vignetteNoiseChannelMixer, VignetteNoiseChannelMixer);

/// Amplitude of the noise. Should be in [0, 1] range. Default amplitude is 0.
@property (nonatomic) CGFloat vignetteNoiseAmplitude;
LTPropertyDeclare(CGFloat, vignetteNoiseAmplitude, VignetteNoiseAmplitude);

/// Vignetting opacity. Should be in [0, 1] range. Default amplitude is 0.
@property (nonatomic) CGFloat vignetteOpacity;
LTPropertyDeclare(CGFloat, vignetteOpacity, VignetteOpacity);

@end
