// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNImageAsset.h"

NS_ASSUME_NONNULL_BEGIN

/// Image asset backed by a \c UIImage. This asset will return an empty image metadata.
@interface PTNStaticImageAsset : NSObject <PTNImageAsset>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c image to be returned when fetching this asset's image.
- (instancetype)initWithImage:(UIImage *)image NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
