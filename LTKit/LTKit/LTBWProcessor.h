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

/// Color filter is a triplet that weights the contribution of each color channel during the
/// conversion process. Color components should be in [0, 1] range. An attempt to pass the black
/// color (all components are zero) will raise an exception.
/// Default value is the NTSC conversion triplet (0.299, 0.587, 0.114).
@property (nonatomic) GLKVector3 colorFilter;

/// Brightens the image. Should be in [-1 1] range. Default value is 0.
@property (nonatomic) CGFloat brightness;

/// Increases the global contrast of the image. Should be in [0, 2] range. Default value is 1.
@property (nonatomic) CGFloat contrast;

/// Changes the exposure of the image. Should be in [0, 2] range. Default value is 1.
@property (nonatomic) CGFloat exposure;

/// Increases the local contrast of the image. Should be in [0, 4] range. Default value is 1.
@property (nonatomic) CGFloat structure;

/// RGBA texture with one row and at most 256 columns that defines greyscale to color mapping.
/// This LUT is used to colorize (add tint) to the BW conversion. Default value is an identity
/// mapping.
@property (strong, nonatomic) LTTexture *colorGradientTexture;

#pragma mark -
#pragma mark Grain
#pragma mark -

/// Grain (noise) texture that modulates with the image. Default value is a constant 0.5, which
/// doesn't affect the image.
@property (strong, nonatomic) LTTexture *grainTexture;

/// Mixes the channels of the grain texture. Default value is (1, 0, 0). Input values are
/// normalized, to remove potential interference with noise amplitude.
@property (nonatomic) GLKVector3 grainChannelMixer;

/// Amplitude of the noise. Should be in [0, 100] range. Default amplitude is 0.
LTBoundedPrimitiveProperty(CGFloat, grainAmplitude, GrainAmplitude);

#pragma mark -
#pragma mark Vignetting
#pragma mark -

/// Color of the vignetting pattern.
@property (nonatomic) GLKVector3 vignetteColor;

/// Noise texture that modulates with the vignetting pattern. Default value is a constant 0.5, which
/// doesn't affect the image.
@property (strong, nonatomic) LTTexture *vignettingTexture;

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

/// Amplitude of the noise. Should be in [0, 100] range. Default amplitude is 0.
@property (nonatomic) CGFloat vignettingNoiseAmplitude;

#pragma mark -
#pragma mark Wide Frame
#pragma mark -

/// In wide frame, percent of the smaller image dimension that the foreground should occupy.
/// Should be in [0-25] range. Default value is 0.
@property (nonatomic) CGFloat wideFrameWidth;

/// In wide frame, percent of the smaller image dimension that the transition should occupy.
/// Should be in [0-25] range. Default value is 0.
@property (nonatomic) CGFloat wideFrameSpread;

/// In wide frame, determines the corner type of the frame by creating an appropriate distance
/// field. Should be in [0-32] range. At 0 value, the corner will be completely straight. Higher
/// values will create a different degrees of roundness, which stem from the remapping the distance
/// field values with the power function. Default value is 0.
@property (nonatomic) CGFloat wideFrameCorner;

/// Noise texture that modulates with the wide frame. Default value is a constant 0.5, which doesn't
/// affect the image.
@property (strong, nonatomic) LTTexture *wideFrameNoise;

/// In wide frame, Mixes the noise channels of the noise texture in order to create the transition
/// noise. Default value is (1, 0, 0). Input values are normalized, to remove potential interference
/// with noise amplitude.
@property (nonatomic) GLKVector3 wideFrameNoiseChannelMixer;

/// In wide frame, Amplitude of the noise. Should be in [0, 100] range. Default amplitude is 1.
@property (nonatomic) CGFloat wideFrameNoiseAmplitude;

/// In wide frame, Color of the foreground and of the transition area. Components should be in
/// [0, 1] range. Default color is white (1, 1, 1).
@property (nonatomic) GLKVector3 wideFrameColor;

#pragma mark -
#pragma mark Narrow Frame
#pragma mark -

/// In narrow frame, percent of the smaller image dimension that the foreground should occupy.
/// Should be in [0-25] range. Default value is 0.
@property (nonatomic) CGFloat narrowFrameWidth;

/// In narrow frame, percent of the smaller image dimension that the transition should occupy.
/// Should be in [0-25] range. Default value is 0.
@property (nonatomic) CGFloat narrowFrameSpread;

/// In narrow frame, determines the corner type of the frame by creating an appropriate distance f
/// field. hould be in [0-32] range. At 0 value, the corner will be completely straight. Higher
/// values will create a different degrees of roundness, which stem from the remapping the distance
/// field values with the power function. Default value is 0.
@property (nonatomic) CGFloat narrowFrameCorner;

/// Noise texture that modulates with the narrow frame. Default value is a constant 0.5, which
/// doesn't affect the image.
@property (strong, nonatomic) LTTexture *narrowFrameNoise;

/// In narrow frame, mixes the noise channels of the noise texture in order to create the transition
/// noise. Default value is (1, 0, 0). Input values are normalized, to remove potential interference
/// with noise amplitude.
@property (nonatomic) GLKVector3 narrowFrameNoiseChannelMixer;

/// In narrow frame, amplitude of the noise. Should be in [0, 100] range. Default amplitude is 1.
@property (nonatomic) CGFloat narrowFrameNoiseAmplitude;

/// In narrow frame, color of the foreground and of the transition area. Components should be in
/// [0, 1] range. Default color is white (1, 1, 1).
@property (nonatomic) GLKVector3 narrowFrameColor;

@end
