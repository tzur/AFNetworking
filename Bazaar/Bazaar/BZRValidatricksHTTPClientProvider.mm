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

@end

@implementation BZRValidatricksHTTPClientProvider

/// Validatricks server host name.
static NSString * const kValidatricksServerHostName = @"api.lightricks.com";

/// Latest version of Validatricks receipt validator.
static NSString * const kLatestValidatorVersion = @"v1";

+ (NSURL *)serverURLFromHostName:(NSString *)hostName {
  return [NSURL URLWithString:
          [NSString stringWithFormat:@"https://%@/store/%@/", hostName, kLatestValidatorVersion]];
}

- (instancetype)init {
  BZRValidatricksSessionConfigurationProvider *sessionConfigurationProvider =
      [[BZRValidatricksSessionConfigurationProvider alloc] init];
  return [self initWithSessionConfigurationProvider:sessionConfigurationProvider
                                           hostName:kValidatricksServerHostName];
}

- (instancetype)initWithSessionConfigurationProvider:
    (id<FBRHTTPSessionConfigurationProvider>)sessionConfigurationProvider
    hostName:(NSString *)hostName {
  if (self = [super init]) {
    _sessionConfigurationProvider = sessionConfigurationProvider;
    _serverURL = [BZRValidatricksHTTPClientProvider serverURLFromHostName:hostName];
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
