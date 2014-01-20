// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// @class LTBicubicFilter
///
/// Class for bicubic filtering of the image. Can be used to resize the input texture with bicubic
/// kernel.
@interface LTBicubicFilter : LTOneShotImageProcessor

- (instancetype)initWithInput:(LTTexture *)texture resizeFector:(CGFloat)resizeFactor;

@end
