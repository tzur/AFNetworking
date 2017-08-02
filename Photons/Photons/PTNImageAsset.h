// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDataAsset.h"

@class LTPath, PTNImageResizer;

@protocol PTNResizingStrategy;

NS_ASSUME_NONNULL_BEGIN

/// Protocol for an image asset, enabling fetching of image and image metadata.
@protocol PTNImageAsset <NSObject>

/// Fetches the image backed by this asset. The returned signal sends a single \c UIImage object on
/// an arbitrary thread, and completes. If the image cannot be fetched the signal errs instead.
///
/// @return <tt>RACSignal<UIImage *></tt>.
- (RACSignal *)fetchImage;

/// Fetches the image metadata of image backed by this asset. The returned signal sends a single
/// \c PTNImageMetadata object on an arbitrary thread, and completes. If the image metadata cannot
/// be fetched the signal errs instead.
///
/// @note The image returned in \c fetchImage may be a transformation (such as rotation or resizing)
/// on an original image. The metadata is fetched from the original image, so some metadata fields
/// related to the transform may not reflect the image that is returned by \c fetchImage.
///
/// @return <tt>RACSignal<PTNImageMetadata *></tt>.
- (RACSignal *)fetchImageMetadata;

@end

NS_ASSUME_NONNULL_END
