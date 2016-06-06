// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTPyramidProcessor.h"

/// Processor for creating an image pyramid out of an input image. It extends LTPyramidProcessor
/// by offering a higher degree of smoothing for each level of the pyramid, by averaging each pixel
/// with its 4-neighborhood.
@interface LTSmoothPyramidProcessor : LTPyramidProcessor

/// Initializes with an input and a set of outputs. It's recommended to use LTPyramidProcessor's
/// \c +levelsForInput: to generate the output textures before calling this initializer.
- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray *)outputs;

/// Determines whether the texel step for the multiple taps should be updated between iterations
/// when upsampling using this processor. Default is \c NO which creates subsampled kernels and
/// allows approximation of larger smoothing kernels when upsampling.
///
/// @note When downsampling the texel step is always being updated.
@property (nonatomic) BOOL updateTexelStepInUpsample;

@end
