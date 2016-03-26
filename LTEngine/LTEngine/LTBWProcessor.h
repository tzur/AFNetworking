// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

@class LTColorGradient;

/// Converts color RGB image to black and white. Controls both the tonal characteristics of the
/// result and additional content that enables a richer conversion: grain, vignetting, tint and
/// frames.
@interface LTBWProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture to be converted to BW and the output.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

#pragma mark -
#pragma mark Tonality
#pragma mark -

/// Brightens the image. Should be in [-1 1] range. Default value is 0.
@property (nonatomic) CGFloat brightness;
LTPropertyDeclare(CGFloat, brightness, Brightness);

/// Increases the global contrast of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat contrast;
LTPropertyDeclare(CGFloat, contrast, Contrast);

/// Changes the exposure of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat exposure;
LTPropertyDeclare(CGFloat, exposure, Exposure);

/// Changes the offset of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat offset;
LTPropertyDeclare(CGFloat, offset, Offset);

/// Increases the local contrast of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat structure;
LTPropertyDeclare(CGFloat, structure, Structure);

/// Color filter is a triplet that weights the contribution of each color channel during the
/// conversion process. Color components should be in [-2, 2] range. The weights are not normalized.
/// An attempt to pass the black color (all components are zero) will raise an exception. Default
/// value is the NTSC conversion triplet (0.299, 0.587, 0.114).
@property (nonatomic) LTVector3 colorFilter;
LTPropertyDeclare(LTVector3, colorFilter, ColorFilter);

/// Gradient that is used to map luminance to color, adding tint to the image.
@property (strong, nonatomic) LTColorGradient *colorGradient;

/// Intensity of the color gradient. A value of 0 will effectively use an identity color gradient. A
/// value of 1 will use the given \c colorGradient. A middle value will linearly interpolate the
/// two. Should be in [0, 1] range. Default value is 0.
@property (nonatomic) CGFloat colorGradientIntensity;
LTPropertyDeclare(CGFloat, colorGradientIntensity, ColorGradientIntensity);

/// Add fade effect to the color gradient mapping. Should be in [0, 1] range. Default value is 0,
/// when no fade applied.
@property (nonatomic) CGFloat colorGradientFade;
LTPropertyDeclare(CGFloat, colorGradientFade, ColorGradientFade);

#pragma mark -
#pragma mark Grain
#pragma mark -

/// Grain (noise) texture that modulates the image. Default value is a constant 0.5, which doesn't
/// affect the image.
///
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

/// Amplitude of the noise. Should be in [0, 1] range. Default amplitude is 1.
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
#pragma mark Frame
#pragma mark -

/// Square frame texture. Frame is mapped as bottom texture in overlay mode, were top layer is the
/// luminance input. Frame is mapped using a "throw-cut" algorithm, where texture center rows or
/// columns corresponding to the smaller dimension are thrown away and not mapped on the image.
/// Passing \c nil will add an empty frame.
@property (strong, nonatomic) LTTexture *frameTexture;

/// Changes the width of the frame. Should be in [-1, 1] range. Default value is 0, which shows the
/// frame at its original size, corrected for the aspect ratio.
@property (nonatomic) CGFloat frameWidth;
LTPropertyDeclare(CGFloat, frameWidth, FrameWidth);

@end
