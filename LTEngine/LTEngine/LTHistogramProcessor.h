// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTImageProcessor.h"

@class LTTexture;

/// Computes a histogram of red, green and blue channels of RGBA image.
@interface LTHistogramProcessor : LTImageProcessor

/// Initializes the processor with input. Input texture pixel format must be
/// \c LTGLPixelFormatRGBA8Unorm.
- (instancetype)initWithInputTexture:(LTTexture *)inputTexture;

/// Histogram values are computed when \c process is called and can be updated if the texture is
/// changed by calling \c process again.

/// Table with 256 values representing a histogram of the red channel. Initial value is zeros.
@property (readonly, nonatomic) cv::Mat1f redHistogram;

/// Table with 256 values representing a histogram of the green channel. Initial value is zeros.
@property (readonly, nonatomic) cv::Mat1f greenHistogram;

/// Table with 256 values representing a histogram of the blue channel. Initial value is zeros.
@property (readonly, nonatomic) cv::Mat1f blueHistogram;

/// Maximum number of entries for a bin in the red histogram. Initial value is 0.
@property (readonly, nonatomic) unsigned long maxRedCount;

/// Maximum number of entries for a bin in the green histogram. Initial value is 0.
@property (readonly, nonatomic) unsigned long maxGreenCount;

/// Maximum number of entries for a bin in the blue histogram. Initial value is 0.
@property (readonly, nonatomic) unsigned long maxBlueCount;

@end
