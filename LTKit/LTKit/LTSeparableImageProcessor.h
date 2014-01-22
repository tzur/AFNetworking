// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTIterativeImageProcessor.h"

/// Separable filter that alternates between horizontal and vertical filtering of the image.
@interface LTSeparableImageProcessor : LTIterativeImageProcessor

/// Initializes a new separable filter processor with a single source texture texture, auxiliary
/// textures and a varying number of output textures.
///
/// @attention program should include \c texelOffset uniform, which allow to traverse the image
/// pixel grid in the fragment shader.
- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)sourceTexture
              auxiliaryTextures:(NSDictionary *)auxiliaryTextures outputs:(NSArray *)outputs;

/// Sets the desired number of iterations for each output. Each iteration includes both a horizontal
/// and a vertical pass.
///
/// @see LTIterativeImageProcessor for more information.
- (void)setIterationsPerOutput:(NSArray *)iterationsPerOutput;

@end
