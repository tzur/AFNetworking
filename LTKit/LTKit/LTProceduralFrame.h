// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// @class ProceduralFrame
///
/// Creates a procedural frame. The frame consists of three regions: foreground, background and
/// transition area. Foreground is shaded with the solid color, background is left untouched by
/// setting alpha to zero and the transition area is modulated with noise to create a visually
/// pleasing result. The roundness of the frame corners can be conrolled in the range between
/// completely straight and very curved connection of the frame's sides.
@interface ProceduralFrame : LTOneShotImageProcessor

/// Initializes a dual frame processor with a noise and output texture.
///
/// @attention Noise is assumed to be with 0.5 mean. Stick to this assumption, unless you want to
/// create a very specific visual result and understand well the underlying frame creation process.
- (instancetype)initWithNoise:(LTTexture *)noise output:(LTTexture *)output;

/// Percent of the smaller image dimension that the foreground should occupy.
/// Should be in [0-25] range. Default value is 0.
@property (nonatomic) CGFloat width;

/// Percent of the smaller image dimension that the transition should occupy.
/// Should be in [0-25] range. Default value is 0.
@property (nonatomic) CGFloat spread;

/// Determines the corner type of the frame by creating an appropriate distance field.
/// Should be in [0-32] range. At 0 value, the corner will be completely straight. Higher values
/// will create a different degrees of roundness, which stem from the remapping the distance field
/// values with the power function. Default value is 0.
@property (nonatomic) CGFloat corner;

/// Mixes the noise channels of the noise texture in order to create the transition noise. Default
/// value is (1, 0, 0). Input values are normalized, to remove potential interference with noise
/// amplitude.
@property (nonatomic) GLKVector3 noiseChannelMixer;

/// Amplitude of the noise. Should be in [0, 100] range. Default amplitude is 1.
@property (nonatomic) CGFloat noiseAmplitude;

/// Color of the foreground and of the transition area. Components should be in [0, 1] range.
/// Default color is white (1, 1, 1).
@property (nonatomic) GLKVector3 color;

@end
