// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTImageCompression.h"

NS_ASSUME_NONNULL_BEGIN

/// Apply lossless LZW compression with TIFF file format on images. The TIFF file format also
/// includes metadata.
@interface LTImageTIFFCompressor : NSObject <LTImageCompression>
@end

NS_ASSUME_NONNULL_END
