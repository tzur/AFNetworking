// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNImageAsset.h"

@class PHAsset, PHContentEditingInputRequestOptions;

NS_ASSUME_NONNULL_BEGIN

/// Image asset backed by a \c UIImage and a \c PHAsset.
///
/// @note Fetching of image is done immediately by supplying the \c UIImage given in initialization
/// and is considered a lightweight operation. Fetching metadata requires asynchronous querying of
/// the \c PHAsset given in initialization and is considered a heavy operation.
@interface PTNPhotoKitImageAsset : NSObject <PTNImageAsset>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes this image asset with \c image as the image to be retuned when fetched and \c asset
/// to be used when fetching image metadata. Fetching metadata is supported for
/// <tt>{PHAssetMediaTypeImage, PHAssetMediaTypeVideo}</tt> \c mediaType. \c PHAssetMediaTypeVideo
/// assets return empty metadata.
- (instancetype)initWithImage:(UIImage *)image asset:(PHAsset *)asset NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
