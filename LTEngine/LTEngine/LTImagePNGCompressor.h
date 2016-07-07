// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageCompressor.h"

NS_ASSUME_NONNULL_BEGIN

/// Apply PNG compression on images. PNG does not support metadata and it will be ignored.
@interface LTImagePNGCompressor : NSObject <LTImageCompressor>
@end

NS_ASSUME_NONNULL_END
