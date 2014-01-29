// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// @class LTOneShotImageProcessor
///
/// Creates multiscale pseudo-noise by exploiting numerical issues of trigonometric functions and
/// bilinear resampling.
@interface LTOneShotMultiscaleNoiseProcessor : LTOneShotImageProcessor

- (instancetype)initWithOutput:(LTTexture *)output;

/// Seed determines the exact values of the noise. Can be used in order to re-create the same noise
/// appearance consistently. Default value is 0.
@property (nonatomic) CGFloat seed;

/// Controls how many islands will appear in noise. Hihger values will create higher number of
/// island-like structures. Recommended values are in [2-20] range. Default value is 2.
@property (nonatomic) CGFloat density;

@end
