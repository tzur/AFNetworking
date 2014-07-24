// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

/// Processor for extracting a boundary from an image which contains single or multiple blobs. The
/// image can be non-binary, which will produce a non-binary boundary as well.
@interface LTPatchBoundaryProcessor : LTOneShotImageProcessor

/// Initializes with an \c input image and an \c output edges texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Threshold to use when creating boundary. Prior to finding the edges, the image is binarized,
/// where: f(x) = { threshold < x <= 1 = 1, 0 <= x < threshold = 0 }. Default value is \c 0.
@property (nonatomic) CGFloat threshold;
LTPropertyDeclare(CGFloat, threshold, Threshold);

@end
