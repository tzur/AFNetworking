// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitImageManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAuthorizationManager;

/// Block returning an instantiated \c PTNPhotoKitImageManager.
typedef id<PTNPhotoKitImageManager> _Nonnull(^PTNPhotoKitImageManagerBlock)();

/// Concrete implementation of \c PTNPhotoKitImageManager using a block to lazily create a
/// \c PTNPhotoKitImageManager, thus avoiding premature authorization requesting. The underlying
/// manager is then proxied.
@interface PTNPhotoKitDeferringImageManager : NSObject <PTNPhotoKitImageManager>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c authorizationManager and a block deferring the default
/// \c PHCachingImageManager.
///
/// @see initWithAuthorizationManager:deferredImageManager:.
- (instancetype)initWithAuthorizationManager:(id<PTNAuthorizationManager>)authorizationManager;

/// Initializes with \c authorizationManager to validate authorization and \c deferredImageManager
/// block used to lazily fetch an underlying manager once and use it to proxy once authorized.
- (instancetype)initWithAuthorizationManager:(id<PTNAuthorizationManager>)authorizationManager
                        deferredImageManager:(PTNPhotoKitImageManagerBlock)deferredImageManager
    NS_DESIGNATED_INITIALIZER;

/// Requests an image representation for the specified asset. Calling this method before receiving
/// PhotoKit authorization will return a \c nil image and an appropriate error in the
/// \c PHImageErrorKey of the \c info dictionary returned by \c resultHandler.
///
/// @see -[PTNPhotoKitImageManager
///     requestImageForAsset:targetSize:contentMode:options:resultHandler:].
- (PHImageRequestID)requestImageForAsset:(PHAsset *)asset
                              targetSize:(CGSize)targetSize
                             contentMode:(PHImageContentMode)contentMode
                                 options:(PHImageRequestOptions *)options
                           resultHandler:(PTNPhotoKitImageManagerHandler)resultHandler;

/// Cancels an asynchronous request. Calling this method before receiving PhotoKit authorization has
/// no effect.
///
/// @see -[PTNPhotoKitImageManager cancelImageRequest:].
- (void)cancelImageRequest:(PHImageRequestID)requestID;

@end

NS_ASSUME_NONNULL_END
