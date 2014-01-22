// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTIterativeImageProcessor.h"

/// Processor for bilateral filter, used to produce edge-aware smoothed image.
///
/// This is not a classic bilateral filter that requires O(n^2) operations per pixel, where n is the
/// filter size. A (mathematically incorrect) assumption that the filter is separable is being made,
/// allowing O(n) operations by filtering only horizontally and vertically.
@interface LTBilateralFilterProcessor : LTIterativeImageProcessor

/// Initializes a new bilateral filter processor with a single input texture and varying number of
/// output textures.
- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray *)outputs;

/// Sets the desired number of bilateral iterations for each output. Each iteration includes both a
/// horizontal and a vertical pass.
///
/// @see LTIterativeImageProcessor for more information.
- (void)setIterationsPerOutput:(NSArray *)iterationsPerOutput;

/// Range sigma used when calculating color differences between neighbour pixels.
@property (nonatomic) float rangeSigma;

@end
