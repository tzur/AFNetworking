// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <LTKit/LTValueObject.h>

#import "PTNDataAsset.h"
#import "PTNImageMetadata.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol for an image in an \c NSData format, enabling fetching of image data and metadata.
@protocol PTNImageDataAsset <PTNDataAsset>

/// Fetches the image metadata of image backed by this asset. The returned signal sends a single
/// \c PTNImageMetadata object on an arbitrary thread, and completes. If the image metadata cannot
/// be fetched the signal errs instead.
- (RACSignal<PTNImageMetadata *> *)fetchImageMetadata;

@end

/// Default implementation of \c PTNImageDataAsset.
@interface PTNImageDataAsset : LTValueObject <PTNImageDataAsset>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c data as the image data. \c uniformTypeIdentifier will be set to \c nil.
- (instancetype)initWithData:(NSData *)data;

/// Initializes with \c data as the image data, the \c uniformTypeIdentifier of the image.
- (instancetype)initWithData:(NSData *)data
       uniformTypeIdentifier:(nullable NSString *)uniformTypeIdentifier NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
