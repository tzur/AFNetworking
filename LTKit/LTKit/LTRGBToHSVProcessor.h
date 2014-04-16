// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// LTRGBToHSVProcessor converts from RGB to HSV color space.
@interface LTRGBToHSVProcessor : LTOneShotImageProcessor

/// Initializes with input RGB image to be converted and output to store the HSV result.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

@end
