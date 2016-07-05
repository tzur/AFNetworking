// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPSession.h"

NS_ASSUME_NONNULL_BEGIN

@class AFHTTPSessionManager, FBRHTTPSessionConfiguration;

/// Adapter that implements the \c FBRHTTPSession protocol using an underlying AFNetworking session.
/// Tasks initiated by the \c FBRHTTPSession protocol methods are delegated to the underlying
/// \c AFHTTPSessionManager.
///
/// @see FBRHTTPSession.
@interface FBRAFNetworkingSessionAdapter : NSObject <FBRHTTPSession>

/// Initializes the receiver using \c sessionManager as the underlying session.
- (instancetype)initWithSessionManager:(AFHTTPSessionManager *)sessionManager
    NS_DESIGNATED_INITIALIZER;

/// Underlying session manager.
@property (readonly, nonatomic) AFHTTPSessionManager *sessionManager;

@end

NS_ASSUME_NONNULL_END
