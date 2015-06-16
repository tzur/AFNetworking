// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Shabtay.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for applying compression on images.
@protocol LTImageCompression

/// Apply compression on \c image and add \c metadata to the resulting \c NSData. An error will be
/// raised if the \c image is \c nil. The \c metadata may be \c nil, or it may include make, model,
/// location, etc. The \c metadata will only be added to compression formats that support it. In
/// case the compression process fails, the method will return \c nil and relevant \c error.
- (nullable NSData *)compressImage:(UIImage *)image metadata:(nullable NSDictionary *)metadata
                             error:(NSError *__autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
