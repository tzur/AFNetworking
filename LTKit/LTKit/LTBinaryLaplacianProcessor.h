// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

/// Processor for filtering an image with the discrete Laplacian kernel with thresholding at 0, so
/// values <= 0 are kept at 0 and values > 0 are set to 1. The Laplacian kernel is defined as
/// [0 1 0; 1 -4 1; 0 1 0].
///
/// Given the fact this processor is almost uniquely used for boundary detection on a given binary
/// image, the min/mag interpolation of the input texture is set to nearest neighbour while
/// processing.
@interface LTBinaryLaplacianProcessor : LTOneShotImageProcessor

/// Initializes with an \c input image and an \c output edges texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

@end
