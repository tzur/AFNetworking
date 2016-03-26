// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAuthorizationManager.h"
#import "PTNOpenURLHandler.h"

@class DBSession;

NS_ASSUME_NONNULL_BEGIN

/// Implementation of the \c PTNAuthorizationManager and \c PTNOpenURLHandler protocols for
/// Dropbox, managing authorization status and flow. Available authorization statuses are
/// <tt>{PTNAuthorizationStatusAuthorized, PTNAuthorizationStatusNotDetermined}</tt>.
///
/// @important One must connect this manager to the OpenURL calls of the hosting app for it to
/// properly work.
@interface PTNDropboxAuthorizationManager : NSObject <PTNAuthorizationManager, PTNOpenURLHandler>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the \c dropboxSession that handles the authorization flow.
- (instancetype)initWithDropboxSession:(DBSession *)dropboxSession NS_DESIGNATED_INITIALIZER;

/// Dropbox session that handles authorization flow.
@property (readonly, nonatomic) DBSession *dropboxSession;

@end

NS_ASSUME_NONNULL_END
