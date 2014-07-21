// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTPropertyMacros.h"

/// Create image border by combining two LTProceduralFrames.
@interface LTImageBorderProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture, which will have a border added to it and the
/// output.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

#pragma mark -
#pragma mark Both Frames
#pragma mark -

/// Roughness gives a convenient way to control the roughness of both inner and outer frames. It
/// is used to compute a scaling factor for noise amplitude of outer and inner frames. It does not
/// change the values outerFrameNoiseAmplitude and innerFrameNoiseAmplitude properties. Should be in
/// [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat roughness;
LTPropertyDeclare(CGFloat, roughness, Roughness);

#pragma mark -
#pragma mark Outer Frame
#pragma mark -

/// Width of the outer frame, as percentage of the smaller image dimension. Should be in [0-25]
/// range. Default value is 0.
@property (nonatomic) CGFloat outerFrameWidth;

/// Spread of the outer frame, as percentage of the smaller image dimension. Should be in [0-25]
/// range. Default value is 0.
@property (nonatomic) CGFloat outerFrameSpread;

/// In outer frame, determines the corner type of the frame by creating an appropriate distance
/// field. Should be in [0-32] range. At 0 value, the corner will be completely straight. Higher
/// values will create a different degrees of roundness, which stem from the remapping the distance
/// field values with the power function. Default value is 0.
@property (nonatomic) CGFloat outerFrameCorner;

/// Noise texture that modulates with the outer frame. Default value is a constant 0.5, which
/// doesn't affect the image.
@property (strong, nonatomic) LTTexture *outerFrameNoise;

/// In outer frame, mixes the noise channels of the noise texture in order to create the transition
/// noise. Default value is (1, 0, 0). Input values are normalized, to remove potential interference
/// with noise amplitude.
@property (nonatomic) GLKVector3 outerFrameNoiseChannelMixer;

/// In outer frame, amplitude of the noise. Should be in [0, 100] range. Default amplitude is 0.
@property (nonatomic) CGFloat outerFrameNoiseAmplitude;

/// In outer frame, color of the foreground and of the transition area. Components should be in
/// [0, 1] range. Default color is white (1, 1, 1).
@property (nonatomic) GLKVector3 outerFrameColor;

#pragma mark -
#pragma mark Inner Frame
#pragma mark -

/// Width of the inner frame, as percentage of the smaller image dimension. Inner frame width is
/// measured from outerFrameWidth inwards. The transition (spread) part of the outer frame is still
/// visible, since the inner frame is layered below the outer frame. Should be in [0-25] range.
/// Default value is 0.
@property (nonatomic) CGFloat innerFrameWidth;

/// Spread of the inner frame, as percentage of the smaller image dimension. Should be in [0-25]
/// range. Default value is 0.
@property (nonatomic) CGFloat innerFrameSpread;

/// In inner frame, determines the corner type of the frame by creating an appropriate distance
/// field. Should be in [0-32] range. At 0 value, the corner will be completely straight. Higher
/// values will create a different degrees of roundness, which stem from the remapping the distance
/// field values with the power function. Default value is 0.
@property (nonatomic) CGFloat innerFrameCorner;

/// Noise texture that modulates with the inner frame. Default value is a constant 0.5, which
/// doesn't affect the image.
@property (strong, nonatomic) LTTexture *innerFrameNoise;

/// In inner frame, mixes the channels of the noise texture in order to create the transition
/// noise. Default value is (1, 0, 0). Input values are normalized, to remove potential interference
/// with noise amplitude.
@property (nonatomic) GLKVector3 innerFrameNoiseChannelMixer;

/// In inner frame, amplitude of the noise. Should be in [0, 100] range. Default amplitude is 0.
@property (nonatomic) CGFloat innerFrameNoiseAmplitude;

/// In inner frame, color of the foreground and of the transition area. Components should be in
/// [0, 1] range. Default color is white (1, 1, 1).
@property (nonatomic) GLKVector3 innerFrameColor;

@end
