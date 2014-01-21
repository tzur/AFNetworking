// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTIterativeImageProcessor.h"

/// Separable filter that alternates between horizontal and vertical filtering of the image.
@interface LTSeparableImageProcessor : LTIterativeImageProcessor

/// Initializes a new separable filter processor with a single input texture and varying number of
/// output textures.
- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)input
                        outputs:(NSArray *)outputs;

/// Sets the desired number of iterations for each output. Each iteration includes both a horizontal
/// and a vertical pass.
///
/// @see LTIterativeImageProcessor for more information.
- (void)setIterationsPerOutput:(NSArray *)iterationsPerOutput;

/// Range sigma used when calculating color differences between neighbour pixels.
//@property (nonatomic) float rangeSigma;

@end

