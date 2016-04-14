// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAuthorizationManager.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake authorization manager for testing.
@interface PTNPhotoKitFakeAuthorizationManager : NSObject <PTNAuthorizationManager>

/// Authorization status returned by the fetcher, default value is
/// \c PHAuthorizationStatusAuthorized.
@property (readwrite, nonatomic) PTNAuthorizationStatus authorizationStatus;

@end

NS_ASSUME_NONNULL_END
