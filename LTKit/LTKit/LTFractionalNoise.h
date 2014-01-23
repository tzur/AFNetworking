// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// @class LTFractionalNoise
///
/// Creates high-frequency pseudo-noise by exploiting numerical issues of trigonometric functions.
@interface LTFractionalNoise : LTOneShotImageProcessor

- (instancetype)initWithOutput:(LTTexture *)output;

/// Update seeds in the shader a
- (void)updateSeeds;

/// Controls how strong the noise is. Should be grater than 0.
@property (nonatomic) CGFloat amplitude;

/// Seed properties that determine the exact values of the noise. Can be used in order to re-create
/// the same noise appearance consistently.
/// Horizontal seed.
@property (nonatomic) CGFloat seed0;

/// Vertical seed.
@property (nonatomic) CGFloat seed1;

/// Velocity seed.
@property (nonatomic) CGFloat seed2;

@end

