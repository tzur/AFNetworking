// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNAuthorizationManager.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNMediaLibraryAuthorizer;

/// Implementation of the \c PTNAuthorizationManager protocol for Media Library, managing
/// authorization status and flow.
@interface PTNMediaLibraryAuthorizationManager : NSObject <PTNAuthorizationManager>

/// Initializes with the default \c PTNMediaLibraryAuthorizer.
- (instancetype)init;

/// Initializes with \c authorizer as the handler of the MediaPlayer authorization flow.
- (instancetype)initWithAuthorizer:(PTNMediaLibraryAuthorizer *)authorizer
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
