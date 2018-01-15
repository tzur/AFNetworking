// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import <LTKit/LTValueObject.h>

#import "PTNImageAsset.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNImageMetadata;

/// Image asset backed by a \c UIImage and image metadata. If no image metadata is given, an empty
/// image metadata is returned.
@interface PTNStaticImageAsset : LTValueObject <PTNImageAsset>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c image to be returned when fetching this asset's image and \c nil image
/// metadata.
- (instancetype)initWithImage:(UIImage *)image;

/// Initializes with \c image to be returned when fetching this asset's image and \c imageMetadata
/// to be returned when fetching this asset's image metadata.
- (instancetype)initWithImage:(UIImage *)image
                imageMetadata:(nullable PTNImageMetadata *)imageMetadata NS_DESIGNATED_INITIALIZER;

/// Image backing this image asset.
@property (readonly, nonatomic) UIImage *image;

/// Metadata for \c image.
@property (readonly, nonatomic) PTNImageMetadata *imageMetadata;

@end

NS_ASSUME_NONNULL_END
