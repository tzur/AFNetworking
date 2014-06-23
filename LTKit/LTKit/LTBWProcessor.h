// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTPropertyMacros.h"

@class LTColorGradient;

/// @class LTBWProcessor
///
/// Converts RGB image to BW (black and white). Controls both the tonal characteristics of the
/// result and additional content that enables a richer conversion: grain, vignetting and frames.
@interface LTBWProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture to be converted to BW and the output.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

#pragma mark -
#pragma mark Tonality
#pragma mark -

/// Brightens the image. Should be in [-1 1] range. Default value is 0.
LTDeclareProperty(CGFloat, brightness, Brightness);

/// Increases the global contrast of the image. Should be in [-1, 1] range. Default value is 0.
LTDeclareProperty(CGFloat, contrast, Contrast);

/// Changes the exposure of the image. Should be in [-1, 1] range. Default value is 0.
LTDeclareProperty(CGFloat, exposure, Exposure);

/// Changes the offset of the image. Should be in [-1, 1] range. Default value is 0.
LTDeclareProperty(CGFloat, offset, Offset);

/// Increases the local contrast of the image. Should be in [-1, 1] range. Default value is 0.
LTDeclareProperty(CGFloat, structure, Structure);

/// Color filter is a triplet that weights the contribution of each color channel during the
/// conversion process. Color components should be in [0, 1] range. An attempt to pass the black
/// color (all components are zero) will raise an exception.
/// Default value is the NTSC conversion triplet (0.299, 0.587, 0.114).
LTDeclareProperty(GLKVector3, colorFilter, ColorFilter);

/// RGBA texture with one row and at most 256 columns that defines greyscale to color mapping.
/// This LUT is used to colorize (add tint) to the BW conversion. Default value is an identity
/// mapping. Setting this property to \c nil will restore the default value.
@property (strong, nonatomic) LTTexture *colorGradientTexture;

/// Intensity of the color gradient. A value of 0 will effectively use an identity color gradient. A
/// value of 1 will use the given \c colorGradientTexture. A middle value will linearly interpolate
/// the two. Should be in [0, 1] range. Default value is 0.
LTDeclareProperty(CGFloat, colorGradientIntensity, ColorGradientIntensity);

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
LTDeclareProperty(GLKVector3, grainChannelMixer, GrainChannelMixer);

/// Amplitude of the noise. Should be in [0, 100] range. Default amplitude is 0.
LTDeclareProperty(CGFloat, grainAmplitude, GrainAmplitude);

#pragma mark -
#pragma mark Vignette
#pragma mark -

/// Color of the vignetting pattern. Color components should be in [0, 1] range. Default color is
/// black (0, 0, 0).
LTDeclareProperty(GLKVector3, vignetteColor, VignetteColor);

/// Percent of the image diagonal where the vignetting pattern is not zero.
/// Should be in [0-100] range. Default value is 0.
LTDeclareProperty(CGFloat, vignetteSpread, VignetteSpread);

/// Determines the corner type of the frame and corresponds to the p-norm which is used to compute
/// the distance field. Should be in [2-16] range. The default value is 2.
/// Corner values determince how the distance field in the shader is created. The corner can be
/// completely round by passing 2 and creating an Euclidean distance field for increasingly higher
/// values, the distance field will become more rectangular. The limit of 16 is due to the precision
/// limits in the shader.
LTDeclareProperty(CGFloat, vignetteCorner, VignetteCorner);

/// Noise textures that modulates with the vignetting pattern. Default value is a constant 0.5,
/// which doesn't affect the image. Set \c noise back to \c nil to restore the default value.
///
/// @attention Noise is assumed to be with 0.5 mean. Stick to this assumption, unless you want to
/// create a very specific visual result and understand well the underlying frame creation process.
@property (strong, nonatomic) LTTexture *vignetteNoise;

/// Mixes the noise channels of the noise texture in order to create the transition noise.
/// Components should be in [0, 1] range. Default value is (1, 0, 0). Input values are normalized,
/// to remove potential interference with noise amplitude.
LTDeclareProperty(GLKVector3, vignetteNoiseChannelMixer, VignetteNoiseChannelMixer);

/// Amplitude of the noise. Should be in [0, 100] range. Default amplitude is 0.
LTDeclareProperty(CGFloat, vignetteNoiseAmplitude, VignetteNoiseAmplitude);

#pragma mark -
#pragma mark Outer Frame
#pragma mark -

/// Width of the outer frame, as percentage of the smaller image dimension. Should be in [0-25]
/// range. Default value is 0.
LTDeclareProperty(CGFloat, outerFrameWidth, OuterFrameWidth);

/// Spread of the outer frame, as percentage of the smaller image dimension. Should be in [0-25]
/// range. Default value is 0.
LTDeclareProperty(CGFloat, outerFrameSpread, OuterFrameSpread);

/// In outer frame, determines the corner type of the frame by creating an appropriate distance
/// field. Should be in [0-32] range. At 0 value, the corner will be completely straight. Higher
/// values will create a different degrees of roundness, which stem from the remapping the distance
/// field values with the power function. Default value is 0.
LTDeclareProperty(CGFloat, outerFrameCorner, OuterFrameCorner);

/// Noise texture that modulates with the outer frame. Default value is a constant 0.5, which
/// doesn't affect the image.
@property (strong, nonatomic) LTTexture *outerFrameNoise;

/// In outer frame, mixes the noise channels of the noise texture in order to create the transition
/// noise. Default value is (1, 0, 0). Input values are normalized, to remove potential interference
/// with noise amplitude.
LTDeclareProperty(GLKVector3, outerFrameNoiseChannelMixer, OuterFrameNoiseChannelMixer);

/// In outer frame, amplitude of the noise. Should be in [0, 100] range. Default amplitude is 0.
LTDeclareProperty(CGFloat, outerFrameNoiseAmplitude, OuterFrameNoiseAmplitude);

/// In outer frame, color of the foreground and of the transition area. Components should be in
/// [0, 1] range. Default color is white (1, 1, 1).
LTDeclareProperty(GLKVector3, outerFrameColor, OuterFrameColor);


#pragma mark -
#pragma mark Inner Frame
#pragma mark -

/// Width of the inner frame, as percentage of the smaller image dimension. Inner frame width is
/// measured from outerFrameWidth inwards. The transition (spread) part of the outer frame is still
/// visible, since the inner frame is layered below the outer frame. Should be in [0-25] range.
/// Default value is 0.
LTDeclareProperty(CGFloat, innerFrameWidth, InnerFrameWidth);

/// Spread of the inner frame, as percentage of the smaller image dimension. Should be in [0-25]
/// range. Default value is 0.
LTDeclareProperty(CGFloat, innerFrameSpread, InnerFrameSpread);

/// In inner frame, determines the corner type of the frame by creating an appropriate distance
/// field. Should be in [0-32] range. At 0 value, the corner will be completely straight. Higher
/// values will create a different degrees of roundness, which stem from the remapping the distance
/// field values with the power function. Default value is 0.
LTDeclareProperty(CGFloat, innerFrameCorner, InnerFrameCorner);

/// Noise texture that modulates with the inner frame. Default value is a constant 0.5, which
/// doesn't affect the image.
@property (strong, nonatomic) LTTexture *innerFrameNoise;

/// In inner frame, mixes the noise channels of the noise texture in order to create the transition
/// noise. Default value is (1, 0, 0). Input values are normalized, to remove potential interference
/// with noise amplitude.
LTDeclareProperty(GLKVector3, innerFrameNoiseChannelMixer, InnerFrameNoiseChannelMixer);

/// In inner frame, amplitude of the noise. Should be in [0, 100] range. Default amplitude is 0.
LTDeclareProperty(CGFloat, innerFrameNoiseAmplitude, InnerFrameNoiseAmplitude);

/// In inner frame, color of the foreground and of the transition area. Components should be in
/// [0, 1] range. Default color is white (1, 1, 1).
LTDeclareProperty(GLKVector3, innerFrameColor, InnerFrameColor);

@end
