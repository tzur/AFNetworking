// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAuthorizationManager, PTNPhotoKitChangeManager, PTNPhotoKitFetcher,
    PTNPhotoKitImageManager, PTNPhotoKitObserver;

/// Asset manager which backs PhotoKit assets.
@interface PTNPhotoKitAssetManager : NSObject <PTNAssetManager>

/// Initializes with a \c PTNPhotoKitFetcher, \c PTNPhotoKitObserver, \c PTNPhotoKitImageManager and
/// \c PTNPhotoKitChangeManager used to interact with the iOS photo library.
- (instancetype)initWithFetcher:(id<PTNPhotoKitFetcher>)fetcher
                       observer:(id<PTNPhotoKitObserver>)observer
                   imageManager:(id<PTNPhotoKitImageManager>)imageManager
           authorizationManager:(id<PTNAuthorizationManager>)authorizationManager
                  changeManager:(id<PTNPhotoKitChangeManager>)changeManager
    NS_DESIGNATED_INITIALIZER;

/// Initializes with the default implementations of \c PTNPhotoKitFetcher and
/// \c PTNPhotoKitChangeManager, \c PTNPHotoKitObserver initialized with the shared iOS photo
/// library, \c PTNPhotoKitImageManager set to \c PHCachingImageManager and the given
/// \c authorizationManager.
///
/// @see -initWithFetcher:observer:imageManager:authorizationManager:changeManager.
- (instancetype)initWithAuthorizationManager:(id<PTNAuthorizationManager>)authorizationManager;

/// Initializes with the default implementations of \c PTNPhotoKitFetcher and
/// \c PTNPhotoKitChangeManager, \c PTNPHotoKitObserver initialized with the shared iOS photo
/// library, \c PTNPhotoKitImageManager set to \c PHCachingImageManager and \c authorizationManager
/// initialized with an instance of \c PTNPhotoKitAuthorizationManager.
///
/// @see -initWithFetcher:observer:imageManager:authorizationManager:changeManager.
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
