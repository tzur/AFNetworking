// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import <MediaPlayer/MPMediaLibrary.h>

NS_ASSUME_NONNULL_BEGIN

/// Encapsulates the Media Library authorization process.
API_AVAILABLE(ios(9.3))
@interface PTNMediaLibraryAuthorizer : NSObject

/// Callback of requests for authorization of the Media Library.
typedef void (^PTNMediaLibraryAuthorizationStatusHandler)(MPMediaLibraryAuthorizationStatus status);

/// Requests the user's permission to access the contents of Media Library. The given \c handler
/// will be called with the authorization status.
- (void)requestAuthorization:(PTNMediaLibraryAuthorizationStatusHandler)handler;

/// Current authorization status.
@property (readonly, nonatomic) MPMediaLibraryAuthorizationStatus authorizationStatus;

@end

NS_ASSUME_NONNULL_END
