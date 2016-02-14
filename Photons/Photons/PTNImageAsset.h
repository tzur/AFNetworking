// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDataAsset.h"

@class LTPath, PTNImageResizer;

@protocol PTNResizingStrategy;

NS_ASSUME_NONNULL_BEGIN

/// Protocol for an image asset, enabling fetching of image and image metadata.
@protocol PTNImageAsset <NSObject>

/// Fetches the image backed by this asset. The returned signal sends a single \c UIImage object on
/// an arbitrary thread, and completes. If the image cannott be fetched the signal errs instead.
///
/// @return <tt>RACSignal<UIImage *></tt>.
- (RACSignal *)fetchImage;

/// Fetches the image metadata of image backed by this asset. The returned signal sends a single
/// \c PTNImageMetadata object on an arbitrary thread, and completes. If the image metadata cannot
/// be fetched the signal errs instead.
///
/// @return <tt>RACSignal<PTNImageMetadata *></tt>.
- (RACSignal *)fetchImageMetadata;

@end

NS_ASSUME_NONNULL_END
