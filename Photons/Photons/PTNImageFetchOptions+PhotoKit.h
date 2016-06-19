// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageFetchOptions.h"

NS_ASSUME_NONNULL_BEGIN

@class PHImageRequestOptions;

@interface PTNImageFetchOptions (PhotoKit)

/// Returns a new \c PHImageRequestOptions with \c deliveryMode and \c resizeMode options from this
/// object.
///
/// @note \c PTNImageResizeModeFast is mapped to \c PHImageRequestOptionsResizeModeNone rather than
/// \c PHImageRequestOptionsResizeModeFast. This is for performance reasons as it's assumed that the
/// images are subsampled to a manageable size prior to fetching, causing the cost of memory
/// consumption along with the downsampling taking place in the displaying view to be smaller than
/// the cost of resizing the image.
- (PHImageRequestOptions *)photoKitOptions;

@end

NS_ASSUME_NONNULL_END
