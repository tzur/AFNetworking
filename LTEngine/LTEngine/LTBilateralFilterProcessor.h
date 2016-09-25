// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTSeparableImageProcessor.h"

/// Processor for bilateral filter, used to produce edge-aware smoothed image.
///
/// This is not a classic bilateral filter that requires O(n^2) operations per pixel, where n is the
/// filter size. A (mathematically incorrect) assumption that the filter is separable is being made,
/// allowing O(n) operations by filtering only horizontally and vertically.
@interface LTBilateralFilterProcessor : LTSeparableImageProcessor

/// Initializes a new bilateral filter processor with a single input texture and varying number of
/// output textures.
- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray *)outputs;

/// Initializes a new bilateral filter processor with a single input texture, a \c guide texture
/// from which the weights will be taken during the smoothing process and varying number of output
/// textures. When \c guide is the same as \c input, the filter operates as a regular bilateral
/// filer.
- (instancetype)initWithInput:(LTTexture *)input guide:(LTTexture *)guide
                      outputs:(NSArray *)outputs;

/// Range sigma used when calculating color differences between neighbour pixels.
@property (nonatomic) float rangeSigma;

@end
