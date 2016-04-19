// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAuthorizationManager, PTNPhotoKitChangeManager, PTNPhotoKitFetcher,
    PTNPhotoKitImageManager, PTNPhotoKitObserver;

/// Asset manager which backs PhotoKit assets.
@interface PTNPhotoKitAssetManager : NSObject <PTNAssetManager>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a \c PTNPhotoKitFetcher, \c PTNPhotoKitObserver, \c PTNPhotoKitImageManager and
/// \c PTNPhotoKitChangeManager used to interact with the iOS photo library.
- (instancetype)initWithFetcher:(id<PTNPhotoKitFetcher>)fetcher
                       observer:(id<PTNPhotoKitObserver>)observer
                   imageManager:(id<PTNPhotoKitImageManager>)imageManager
           authorizationManager:(id<PTNAuthorizationManager>)authorizationManager
                  changeManager:(id<PTNPhotoKitChangeManager>)changeManager
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
