// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTIterativeImageProcessor.h"

/// Processor for creating an image pyramid out of a large input image. This processor uses the
/// basic interpolation given by OpenGL: either nearest neighbour or bilinear. This is provided by
/// the user by setting the min/mag interpolation filters of the input and output textures prior to
/// processing. If nearest neighbour interpolation is used, processor will use (1:2:end) sampling
/// pattern (in Matlab notation).
/// For custom pyramids, derive from this class and create your own fragment shader.
@interface LTPyramidProcessor : LTIterativeImageProcessor

/// Creates and returns an array of LTTexture objects with dyadic scaling of level i to level i + 1,
/// where the number of levels is ceil(log2(min(input.size))) - 1. The textures will be created
/// with the same precision and format of the input texture.
///
/// For example, for input size (15, 13) the outputs will be [(8, 7), (4, 4)].
+ (NSArray *)levelsForInput:(LTTexture *)input;

/// Initializes with an input and a set of outputs. It's recommended to use \c +levelsForInput: to
/// generate the output textures before calling this initializer.
- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray *)outputs;

@end
