// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPSessionConfiguration.h"

#import "FBRCompare.h"
#import "FBRHTTPSessionRequestMarshalling.h"
#import "FBRHTTPSessionSecurityPolicy.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBRHTTPSessionConfiguration

@synthesize sessionConfiguration = _sessionConfiguration;

- (instancetype)init {
  return [self initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                         requestMarshalling:[[FBRHTTPSessionRequestMarshalling alloc] init]
                             securityPolicy:[FBRHTTPSessionSecurityPolicy standardSecurityPolicy]];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
                          requestMarshalling:(FBRHTTPSessionRequestMarshalling *)requestMarshalling
                              securityPolicy:(FBRHTTPSessionSecurityPolicy *)securityPolicy {
  if (self = [super init]) {
    _sessionConfiguration = [sessionConfiguration copy];
    _requestMarshalling = [requestMarshalling copy];
    _securityPolicy = [securityPolicy copy];
  }
  return self;
}

- (NSURLSessionConfiguration *)sessionConfiguration {
  return [_sessionConfiguration copy];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(id)object {
  if (object == self) {
    return YES;
  } else if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  FBRHTTPSessionConfiguration *configuration = object;
  return FBRCompare(self.sessionConfiguration, configuration.sessionConfiguration) &&
      FBRCompare(self.requestMarshalling, configuration.requestMarshalling) &&
      FBRCompare(self.securityPolicy, configuration.securityPolicy);
}

- (NSUInteger)hash {
  return self.sessionConfiguration.hash ^ self.requestMarshalling.hash ^ self.securityPolicy.hash;
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

@end

NS_ASSUME_NONNULL_END
