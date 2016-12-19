// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import <Fiber/FBRHTTPClientProvider.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBRHTTPSessionConfigurationProvider;

/// Provider used to provide an HTTP client that can be used to make HTTP requests with
/// Validatricks.
@interface BZRValidatricksHTTPClientProvider : NSObject <FBRHTTPClientProvider>

/// Returns a URL to the latest version of Validatricks receipt validator. The returned URL is an
/// HTTPS URL.
+ (NSURL *)defaultValidatricksServerURL;

/// Initializes with the default Validatricks session configuration provider which is
/// \c BZRValidatricksSessionConfigurationProvider. \c serverURL will be initialized to be
/// \c defaultValidatricksServerURL.
- (instancetype)init;

/// Initializes with \c sessionConfigurationProvider, used to provide the session configuration in
/// order to create an HTTP client. \c serverURL is the URL to connect to by the returned HTTP
/// clients.
- (instancetype)initWithSessionConfigurationProvider:
    (id<FBRHTTPSessionConfigurationProvider>)sessionConfigurationProvider
    serverURL:(NSURL *)serverURL NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
