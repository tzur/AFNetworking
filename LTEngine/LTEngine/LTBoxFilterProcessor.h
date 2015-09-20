// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTSeparableImageProcessor.h"

/// Processor for box filter, which computes an average in 7x7 neighbourhood of each pixel.
@interface LTBoxFilterProcessor : LTSeparableImageProcessor

/// Initializes a new box filter processor with a single input texture and varying number of output
/// textures.
- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray *)outputs;

@end
