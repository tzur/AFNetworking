// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNPhotoKitFetcher, PTNPhotoKitObserver;

/// Asset manager which backs PhotoKit assets.
@interface PTNPhotoKitAssetManager : NSObject <PTNAssetManager>

/// Initializes with a fetcher and observer.
- (instancetype)initWithFetcher:(PTNPhotoKitFetcher *)fetcher
                       observer:(PTNPhotoKitObserver *)observer NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
