// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

/// Processor for extracting a boundary from an image which contains single or multiple blobs. The
/// image can be non-binary, which will produce a non-binary boundary as well.
@interface LTBoundaryExtractor : LTOneShotImageProcessor

/// Initializes with an \c input image and an \c output edges texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

@end
