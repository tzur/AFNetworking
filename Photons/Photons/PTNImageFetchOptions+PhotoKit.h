// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageFetchOptions.h"

NS_ASSUME_NONNULL_BEGIN

@class PHImageRequestOptions;

@interface PTNImageFetchOptions (PhotoKit)

/// Returns a new \c PHImageRequestOptions with \c deliveryMode and \c resizeMode options from this
/// object.
- (PHImageRequestOptions *)photoKitOptions;

@end

NS_ASSUME_NONNULL_END
