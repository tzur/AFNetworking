// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNPhotoKitFetcher, PTNPhotoKitImageManager, PTNPhotoKitObserver;

/// Asset manager which backs PhotoKit assets.
@interface PTNPhotoKitAssetManager : NSObject <PTNAssetManager>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a fetcher, observer and image manager.
- (instancetype)initWithFetcher:(id<PTNPhotoKitFetcher>)fetcher
                       observer:(id<PTNPhotoKitObserver>)observer
                   imageManager:(id<PTNPhotoKitImageManager>)imageManager NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
