// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTNVideoAsset.h"

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Video asset backed by an \c AVAsset.
@interface PTNPhotoKitVideoAsset : NSObject <PTNVideoAsset>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c asset as the \c AVAsset that that receiver is backed by.
- (instancetype)initWithAVAsset:(AVAsset *)asset NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
