// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRUserIDProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRCloudKitAccountInfoProvider;

/// Provides the user record ID supplied via iCloud. On initialization fetches the user record ID
/// and sets it to \c userIdentifier if it exists.
@interface BZRiCloudUserIDProvider : NSObject <BZRUserIDProvider>

/// Initializes with a newly created \c BZRCloudKitAccountInfoProvider with a container identifier
/// of \c @"iCloud.com.lightricks.Bazaar".
- (instancetype)init;

/// Initializes with \c accountInfoProvider, used to provide the user record ID.
- (instancetype)initWithCloudKitAccountInfoProvider:
    (BZRCloudKitAccountInfoProvider *)accountInfoProvider NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
