// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import <Fiber/FBRHTTPClientProvider.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBRHTTPSessionConfigurationProvider;

/// Provider used to provide an HTTP client that can be used to make HTTP requests with
/// Validatricks.
@interface BZRValidatricksHTTPClientProvider : NSObject <FBRHTTPClientProvider>

/// Initializes with the default Validatricks session configuration provider which is
/// \c BZRValidatricksSessionConfigurationProvider. \c serverURL will be initialized to be
/// \c defaultValidatricksServerURL.
- (instancetype)init;

/// Initializes with \c sessionConfigurationProvider, used to provide the session configuration in
/// order to create an HTTP client. \c hostName is the name of the host to connect to by the
/// returned HTTP clients.
- (instancetype)initWithSessionConfigurationProvider:
    (id<FBRHTTPSessionConfigurationProvider>)sessionConfigurationProvider
    hostName:(NSString *)hostName NS_DESIGNATED_INITIALIZER;

/// Validatircks server URL.
@property (readonly, nonatomic) NSURL *serverURL;

@end

NS_ASSUME_NONNULL_END
