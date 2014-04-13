// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// @class LTRGBToHSVProcessor
///
/// Converts from RGB to HSV color space.
@interface LTRGBToHSVProcessor : LTOneShotImageProcessor

/// Initialize with input RGB image to be converted and output to store the HSV result.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

@end
