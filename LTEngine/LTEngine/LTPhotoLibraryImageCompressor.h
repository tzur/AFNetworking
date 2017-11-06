// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTImageCompressor.h"

NS_ASSUME_NONNULL_BEGIN

/// Compresses image using \c LTImageHEICCompressor on supported devices or with
/// \c LTImageJPEGCompressor as a fallback option.
@interface LTPhotoLibraryImageCompressor : NSObject <LTImageCompressor>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the underlying compressor with the given \c quality in the range of \c [0, 1]. The
/// underlying compressor is \c LTImageHEICCompressor on supported devices or
/// \c LTImageJPEGCompressor otherwise. \c quality \c 1 means maximal storage and best quality and
/// \c 0 means minimal storage but lowest quality. \c quality must be in <tt>[0, 1]</tt> range.
- (instancetype)initWithQuality:(CGFloat)quality NS_DESIGNATED_INITIALIZER;

/// Quality of the source texture in the range <tt>[0, 1]</tt>. Default value is \c 1 which means
/// maximal storage and best quality and value of \c 0 means minimal storage but lowest quality.
@property (readonly, nonatomic) CGFloat quality;

@end

NS_ASSUME_NONNULL_END
