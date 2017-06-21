// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTNAVAssetFetchOptions.h"

NS_ASSUME_NONNULL_BEGIN

@class PHVideoRequestOptions;

@interface PTNAVAssetFetchOptions (PhotoKit)

/// Creates and returns a new \c PHVideoRequestOptions corresponding to the receiver.
- (PHVideoRequestOptions *)photoKitOptions;

@end

NS_ASSUME_NONNULL_END
