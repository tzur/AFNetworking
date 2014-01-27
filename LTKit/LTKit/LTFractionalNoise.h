// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// @class LTFractionalNoise
///
/// Creates high-frequency pseudo-noise by exploiting numerical issues of trigonometric functions.
@interface LTFractionalNoise : LTOneShotImageProcessor

/// Initializes a noise processor with an output texture. By default, the amplitude of the noise is
/// 1.0.
- (instancetype)initWithOutput:(LTTexture *)output;

/// Update seeds in the shader, by setting a random value to each on of the seed properties:
/// horizontalSeed, verticalSeed and velocitySeed.
- (void)updateSeeds;

/// Controls how strong the noise is. Should be grater than 0.
@property (nonatomic) CGFloat amplitude;

/// Seed properties that determine the exact values of the noise. Can be used in order to re-create
/// the same noise appearance consistently.

/// Horizontal seed.
@property (nonatomic) CGFloat horizontalSeed;

/// Vertical seed.
@property (nonatomic) CGFloat verticalSeed;

/// Velocity seed.
@property (nonatomic) CGFloat velocitySeed;

@end

