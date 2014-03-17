// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// @class LTProceduralFrame
///
/// Creates a procedural frame. The frame consists of three regions: foreground, background and
/// transition area. Foreground is shaded with the solid color, background is left untouched by
/// setting alpha to zero and the transition area is modulated with noise to create a visually
/// pleasing result. The roundness of the frame corners can be conrolled in the range between
/// completely straight and very curved connection of the frame's sides.
@interface LTProceduralFrame : LTOneShotImageProcessor

/// Initializes a procedural frame processor with an output texture.
- (instancetype)initWithOutput:(LTTexture *)output;

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

/// Noise textures that modulates with the frame. Default value is a constant 0.5, which doesn't
/// affect the image.
/// @attention Noise is assumed to be with 0.5 mean. Stick to this assumption, unless you want to
/// create a very specific visual result and understand well the underlying frame creation process.
@property (strong, nonatomic) LTTexture *noise;

/// Mixes the noise channels of the noise texture in order to create the transition noise. Default
/// value is (1, 0, 0). Input values are normalized, to remove potential interference with noise
/// amplitude.
@property (nonatomic) GLKVector3 noiseChannelMixer;

/// Amplitude of the noise. Should be in [0, 100] range. Default amplitude is 1.
@property (nonatomic) CGFloat noiseAmplitude;

/// Color of the foreground and of the transition area. Components should be in [0, 1] range.
/// Default color is white (1, 1, 1).
@property (nonatomic) GLKVector3 color;

/// Maximum supported width of the frame, as percentage of the smaller image dimension.
@property (nonatomic, readonly) CGFloat maxWidth;

@end
