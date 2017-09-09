// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTImageCompressor.h"

NS_ASSUME_NONNULL_BEGIN

/// Compresses image using \c LTImageHEICCompressor on supported devices or with
/// \c LTImageJPEGCompressor as a fallback option.
@interface LTPhotoLibraryImageCompressor : NSObject <LTImageCompressor>
@end

NS_ASSUME_NONNULL_END
