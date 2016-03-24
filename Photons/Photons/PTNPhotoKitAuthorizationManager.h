// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAuthorizationManager.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNPhotoKitAuthorizer;

/// Implementation of the \c PTNAuthorizationManager protocol for PhotoKit, managing authorization
/// status and flow. Available authorization statuses are <tt>{PTNAuthorizationStatusAuthorized,
/// PTNAuthorizationStatusDenied, PTNAuthorizationStatusRestricted,
/// PTNAuthorizationStatusNotDetermined}</tt>.
@interface PTNPhotoKitAuthorizationManager : NSObject <PTNAuthorizationManager>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c authorizer as the handler of the PhotoKit authorization flow.
- (instancetype)initWithPhotoKitAuthorizer:(PTNPhotoKitAuthorizer *)authorizer
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
