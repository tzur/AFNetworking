// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <LTKit/LTValueObject.h>

#import "PTNDataAsset.h"
#import "PTNImageAsset.h"
#import "PTNImageMetadata.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol for an image in an \c NSData format, enabling fetching of image data and metadata.
@protocol PTNImageDataAsset <PTNDataAsset, PTNImageAsset>
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
