// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitImageManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAuthorizationManager;

/// Block returning an instantiated \c PTNPhotoKitImageManager.
typedef id<PTNPhotoKitImageManager> _Nonnull(^PTNPhotoKitImageManagerBlock)();

/// Concrete implementation of \c PTNPhotoKitImageManager using a block to lazily create a
/// \c PTNPhotoKitImageManager, thus avoiding premature authorization requesting.
///
/// On every method call, \c authorizationManager is queried for the authorization status. If the
/// status is positive, an underlying \c PTNPhotoKitImageManager is created if it wasn't already
/// created, and the method call is forwarded to the underlying image manager. If the authorization
/// status is not positive, the method call has no effect and an error with error code
/// \c PTNErrorCodeNotAuthorized is returned if the method returns error in any way.
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

@end

NS_ASSUME_NONNULL_END
