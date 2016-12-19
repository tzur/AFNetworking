// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import <Fiber/FBRHTTPClientProvider.h>

NS_ASSUME_NONNULL_BEGIN

/// Provider that can provide HTTP clients with different host names. The provider holds a list of
/// client providers, and each time \c HTTPClient is invoked, the provider calls \c HTTPClient on
/// one of those providers by their ordering in the list.
@interface BZRMultiHostValidatricksClientProvider : NSObject <FBRHTTPClientProvider>

/// Initializes with \c hostNames. Each hostName in \c hostNames is used to create a new client
/// provider with which to return HTTP clients. The client providers will be of type
/// \c BZRValidatricksHTTPClientProvider, which will be initialized with \c
/// BZRValidatricksSessionConfigurationProvider in addition to the host name.
- (instancetype)initWithHostNames:(NSArray<NSString *> *)hostNames;

/// Initializes with \c clientProviders, used to return HTTP clients with.
- (instancetype)initWithClientProviders:(NSArray<id<FBRHTTPClientProvider>> *)clientProviders
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
