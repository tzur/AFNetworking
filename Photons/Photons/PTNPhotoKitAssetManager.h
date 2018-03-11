// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAuthorizationManager, PTNPhotoKitAssetResourceManager, PTNPhotoKitChangeManager,
    PTNPhotoKitFetcher, PTNPhotoKitImageManager, PTNPhotoKitObserver;

@class PTNImageResizer;

/// Asset manager which backs PhotoKit assets.
@interface PTNPhotoKitAssetManager : NSObject <PTNAssetManager>

/// Initializes with the default implementations of \c PTNPhotoKitFetcher,
/// \c PTNPhotoKitChangeManager and \c PTNPhotoKitDeferringImageManager, \c PTNPHotoKitObserver
/// initialized with the shared iOS photo library and \c authorizationManager initialized with an
/// instance of \c PTNPhotoKitAuthorizationManager.
///
/// @see -initWithFetcher:observer:imageManager:authorizationManager:changeManager.
- (instancetype)init;

/// Initializes with the default implementations of \c PTNPhotoKitFetcher
/// \c PTNPhotoKitChangeManager and \c PTNImageResizer. \c PTNPhotoKitDeferringImageManager
/// initialized with the given \c authorizationManager, \c PTNPHotoKitObserver initialized with the
/// shared iOS photo library and the given \c authorizationManager.
///
/// @see -initWithFetcher:observer:imageManager:authorizationManager:changeManager.
- (instancetype)initWithAuthorizationManager:(id<PTNAuthorizationManager>)authorizationManager;

/// Initializes with a \c PTNPhotoKitFetcher, \c PTNPhotoKitObserver, \c PTNPhotoKitImageManager and
/// \c PTNPhotoKitChangeManager used to interact with the iOS photo library and \c PTNImageResizer
/// to resize images.
- (instancetype)initWithFetcher:(id<PTNPhotoKitFetcher>)fetcher
                       observer:(id<PTNPhotoKitObserver>)observer
                   imageManager:(id<PTNPhotoKitImageManager>)imageManager
           assetResourceManager:(id<PTNPhotoKitAssetResourceManager>)assetResourceManager
           authorizationManager:(id<PTNAuthorizationManager>)authorizationManager
                  changeManager:(id<PTNPhotoKitChangeManager>)changeManager
                   imageResizer:(PTNImageResizer *)imageResizer NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
