// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

@class LTTexture;

/// Resizes an image using aspect fill with CoreGraphics.
@interface LTAspectFillResizeProcessor : LTImageProcessor

/// Initializes with an input texture to be resized and the ouptut texture to place the resized
/// image in.
- (instancetype)initWithInput:(LTTexture *)inputTexture andOutput:(LTTexture *)outputTexture;

@end
