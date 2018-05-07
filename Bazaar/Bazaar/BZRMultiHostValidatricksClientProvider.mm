// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRMultiHostValidatricksClientProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRValidatricksHTTPClientProvider.h"
#import "BZRValidatricksSessionConfigurationProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRMultiHostValidatricksClientProvider ()

/// Providers that are used to return HTTP clients with.
@property (readonly, nonatomic) NSArray<id<FBRHTTPClientProvider>> *clientProviders;

/// The last client provider used in returning a client.
@property (readwrite, nonatomic) NSUInteger lastUsedClientProvider;

@end

@implementation BZRMultiHostValidatricksClientProvider

/// Validatricks default servers host names.
static NSArray<NSString *> * const kDefaultValidatricksHostNames = @[
  @"oregon-api.lightricks.com",
  @"virginia-api.lightricks.com",

  // Validatricks Hong-Kong server used to simply redirect all HTTP request to the Tokyo server by
  // sending the client an HTTP 301 response. This is problematic since Chinese clients (in some
  // regions in China) may have issues accessing cloud services outside of China. The desired
  // behavior is that the server will actively proxy requests to the Tokyo server and forward the
  // responses to clients. Replacing the HTTP redirection mechanism with proxy may break clients
  // using older versions of Bazaar due to the SSL pinning that did not contain the HK server
  // certificate. In order to not affect users with old versions of Bazaar a specialized route was
  // added to the HK server - "/proxy/*", which performs the proxying while all other routes still
  // perform the HTTP redirection. Bazaar should revert to using the default route once it will be
  // changed to perform proxying instead of redirection, which should happen when the adoption of
  // newer Bazaar revisions, that contain the HK server certificate, is high enough.
  @"hk-api.lightricks.com/proxy",
  @"frankfurt-api.lightricks.com",
  @"ireland-api.lightricks.com",
  @"tokyo-api.lightricks.com",
  @"sydney-api.lightricks.com"
];

- (instancetype)init {
  return [self initWithHostNames:kDefaultValidatricksHostNames];
}

- (instancetype)initWithHostNames:(NSArray<NSString *> *)hostNames {
  BZRValidatricksSessionConfigurationProvider *sessionConfigurationProvider =
      [[BZRValidatricksSessionConfigurationProvider alloc] init];
  NSArray<id<FBRHTTPClientProvider>> *clientProviders =
      [hostNames lt_map:^BZRValidatricksHTTPClientProvider *(NSString *hostName) {
        return [[BZRValidatricksHTTPClientProvider alloc]
                initWithSessionConfigurationProvider:sessionConfigurationProvider
                hostName:hostName];
      }];
  return [self initWithClientProviders:clientProviders];
}

- (instancetype)initWithClientProviders:(NSArray<id<FBRHTTPClientProvider>> *)clientProviders {
  if (self = [super init]) {
    _clientProviders = clientProviders;
    _lastUsedClientProvider = -1;
  }
  return self;
}

#pragma mark -
#pragma mark FBRHTTPClientProvider
#pragma mark -

- (FBRHTTPClient *)HTTPClient {
  NSUInteger selectedClientProviderIndex =
      (self.lastUsedClientProvider + 1) % self.clientProviders.count;
  self.lastUsedClientProvider = selectedClientProviderIndex;
  return [self.clientProviders[selectedClientProviderIndex] HTTPClient];
}

@end

NS_ASSUME_NONNULL_END
