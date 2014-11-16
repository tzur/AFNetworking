// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTImageProcessor.h"

@class LTTexture;

/// The basic oil painting algorithm computes a local intensity histogram and per-channel tables
/// with the sum of channel values at each intensity bin. The final value at each channel is the
/// sum of values in the maximum intensity bin, divided by the number of entries.
/// See: http://spinroot.com/pico/
/// Basic algorithm does not add additional common oil painting simulation effects such as texture
/// or strokes.
@interface LTBasicOilPaintingProcessor : LTImageProcessor

/// Initializes the processor with input and output textures.
- (instancetype)initWithInputTexture:(LTTexture *)inputTexture
                       outputTexture:(LTTexture *)outputTexture;

/// Quantization level of the result. Should be in [2, 255] range. Default value is 20.
@property (nonatomic) NSUInteger quantization;
LTPropertyDeclare(NSUInteger, quantization, Quantization);

/// Radius is equal to half of the sliding window size that is used for computing the neighborhood
/// statistics in the algorithm. Higher values will result in more coarse appearance and will have a
/// significant impact on the processing time of the algorithm. Should be in [1, 100] range. Default
/// value is 3.
@property (nonatomic) NSUInteger radius;
LTPropertyDeclare(NSUInteger, radius, Radius);

@end
