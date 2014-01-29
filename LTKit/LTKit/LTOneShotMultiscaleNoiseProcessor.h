// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

@interface LTOneShotMultiscaleNoiseProcessor : LTOneShotImageProcessor

- (instancetype)initWithOutput:(LTTexture *)output;

/// Seed determines the exact values of the noise. Can be used in order to re-create the same noise
/// appearance consistently.
@property (nonatomic) CGFloat seed;

@property (nonatomic) CGFloat density;

/// Default: aspect ratio.
@property (nonatomic) CGFloat directionality;

@end
