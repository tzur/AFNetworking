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
  @"frankfurt-api.lightricks.com",
  @"ireland-api.lightricks.com",
  @"sydney-api.lightricks.com",
  @"tokyo-api.lightricks.com",
  @"singapore-api.lightricks.com"
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
