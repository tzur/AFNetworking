// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRValidatricksHTTPClientProvider.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/FBRHTTPSessionConfigurationProvider.h>

#import "BZRValidatricksSessionConfigurationProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRValidatricksHTTPClientProvider ()

/// Provider used to provide the session configuration used in creating an HTTP client.
@property (readonly, nonatomic) id<FBRHTTPSessionConfigurationProvider>
    sessionConfigurationProvider;

/// Validatircks server URL.
@property (readonly, nonatomic) NSURL *serverURL;

@end

@implementation BZRValidatricksHTTPClientProvider

/// Validatricks server host name.
static NSString * const kValidatricksServerHostName = @"api.lightricks.com";

/// Latest version of Validatricks receipt validator.
static NSString * const kLatestValidatorVersion = @"v1";

+ (NSURL *)defaultValidatricksServerURL {
  NSString *serverURLString = [NSString stringWithFormat:@"https://%@/store/%@/",
                               kValidatricksServerHostName, kLatestValidatorVersion];
  return [NSURL URLWithString:serverURLString];
}

- (instancetype)init {
  BZRValidatricksSessionConfigurationProvider *sessionConfigurationProvider =
      [[BZRValidatricksSessionConfigurationProvider alloc] init];
  return [self initWithSessionConfigurationProvider:sessionConfigurationProvider
                                          serverURL:[[self class] defaultValidatricksServerURL]];
}

- (instancetype)initWithSessionConfigurationProvider:
    (id<FBRHTTPSessionConfigurationProvider>)sessionConfigurationProvider
    serverURL:(NSURL *)serverURL {
  if (self = [super init]) {
    _sessionConfigurationProvider = sessionConfigurationProvider;
    _serverURL = serverURL;
  }
  return self;
}

- (FBRHTTPClient *)HTTPClient {
  FBRHTTPSessionConfiguration *sessionConfiguration =
      [self.sessionConfigurationProvider HTTPSessionConfiguration];
  return [FBRHTTPClient clientWithSessionConfiguration:sessionConfiguration baseURL:self.serverURL];
}

@end

NS_ASSUME_NONNULL_END
