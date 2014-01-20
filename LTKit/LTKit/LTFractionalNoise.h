// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// @class LTFractionalNoise
///
/// Creates pseudo-noise exploiting numerical issues of trigonometric functions.
@interface LTFractionalNoise : LTOneShotImageProcessor

- (instancetype)initWithOutput:(LTTexture *)output;

// Controls how smooth the noise is. Should be in [0-1] range.
@property (nonatomic) CGFloat frequency;
// Controls how strong the noise is. Should be grater than 0.
@property (nonatomic) CGFloat amplitude;

@end

