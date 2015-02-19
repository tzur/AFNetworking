// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTPropertyMacros.h"

@class LTColorGradient;

/// Types of rotations available for lightleak textures.
typedef NS_ENUM(NSUInteger, LTLightLeakRotation) {
  LTLightLeakRotation0 = 0,
  LTLightLeakRotation90,
  LTLightLeakRotation180,
  LTLightLeakRotation270
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

/// Changes the local contrast of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat structure;
LTPropertyDeclare(CGFloat, structure, Structure);

/// Changes the saturation of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat saturation;
LTPropertyDeclare(CGFloat, saturation, Saturation);

#pragma mark -
#pragma mark Color Gradient
#pragma mark -

/// Gradient that is used to map luminance to color, adding tint to the image.
@property (strong, nonatomic) LTColorGradient *colorGradient;

/// Intensity of the color gradient. A value of 0 will use the original image. A value of 1 will use
/// the intensity of the original mapped to color with a given \c colorGradientTexture. A middle
/// value will interpolate between the two. Should be in [0, 1] range. Default value is 0.
@property (nonatomic) CGFloat colorGradientIntensity;
LTPropertyDeclare(CGFloat, colorGradientIntensity, ColorGradientIntensity);

/// Reduces the contrast of color gradient mapping. Should be in [0, 1] range. Default value is 0,
/// when no fade applied.
@property (nonatomic) CGFloat colorGradientFade;
LTPropertyDeclare(CGFloat, colorGradientFade, ColorGradientFade);

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
#pragma mark Vignette
#pragma mark -

/// Intensity of the vignetting pattern. Should be in [-1, 1] range, where smaller numbers indicate
/// a darker vignetting. Default is 0, which does not apply any vignetting at all.
@property (nonatomic) CGFloat vignetteIntensity;
LTPropertyDeclare(CGFloat, vignetteIntensity, VignetteIntensity);

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

/// Controls how abrupt the transition of the vignetting pattern is. Should be in [0, 1] range.
/// Default value is 0. Higher values correspond to more abrupt transition.
@property (nonatomic) CGFloat vignetteTransition;
LTPropertyDeclare(CGFloat, vignetteTransition, VignetteTransition);

#pragma mark -
#pragma mark Textures
#pragma mark -

/// Square asset texture. RGB channels of this texture are blended using screen mode and intended
/// to store a light leak. Alpha channel is blended in overlay mode and intended to store a frame
/// pattern. The texture should be square. Default texture has 0.0 across rgb channels and 0.5 in
/// alpha channel. Passing \c nil will set \c assetTexture to default texture.
@property (strong, nonatomic) LTTexture *assetTexture;

/// Intensity of the light leak. Should be in [0, 1] range. Default value is 0.
@property (nonatomic) CGFloat lightLeakIntensity;
LTPropertyDeclare(CGFloat, lightLeakIntensity, LightLeakIntensity);

/// Rotation of the light leak. Default value is \c LTLightLeakRotation0.
@property (nonatomic) LTLightLeakRotation lightLeakRotation;

/// Width of the frame. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat frameWidth;
LTPropertyDeclare(CGFloat, frameWidth, FrameWidth);

@end
