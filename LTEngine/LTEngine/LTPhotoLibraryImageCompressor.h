// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTImageCompressor.h"

NS_ASSUME_NONNULL_BEGIN

/// Compresses image using \c LTImageHEICCompressor on supported devices or with
/// \c LTImageJPEGCompressor as a fallback option.
@interface LTPhotoLibraryImageCompressor : NSObject <LTImageCompressor>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the compressor with the given \c quality in the range of \c [0, 1]. If quality is
/// outside the range it will be clamped. The compressor will actually use one of two compressors:
/// \c LTImageHEICCompressor on supported devices or \c LTImageJPEGCompressor otherwise.
- (instancetype)initWithQuality:(CGFloat)quality NS_DESIGNATED_INITIALIZER;

/// Compression quality in the range <tt>[0, 1]</tt>, where \c 1 yields largest output size and best
/// quality and \c 0 yields minimal output size but lowest quality.
@property (readonly, nonatomic) CGFloat quality;

@end

NS_ASSUME_NONNULL_END
