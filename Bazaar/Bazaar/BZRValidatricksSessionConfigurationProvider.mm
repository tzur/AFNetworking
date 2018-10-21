// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksSessionConfigurationProvider.h"

#import <Fiber/FBRHTTPRequest.h>
#import <Fiber/FBRHTTPSessionConfiguration.h>
#import <Fiber/FBRHTTPSessionRequestMarshalling.h>
#import <Fiber/FBRHTTPSessionSecurityPolicy.h>

#import "BZRValidatricksHKServerCert.h"
#import "BZRValidatricksServerCert.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRValidatricksSessionConfigurationProvider ()

/// Certificates used to validate the Validatricks server's certificates against.
@property (readonly, nonatomic, nullable) NSSet<NSData *> *pinnedCertificates;

@end

@implementation BZRValidatricksSessionConfigurationProvider

/// Default API key for Validatricks server.
static NSString * const kValidatricksAPIKey = @"AkPQ45BJFN8GdEuCA9WTm7zaauQSVAil6ZtMp1U3";

/// HTTP header name to use for API key in case API key is required by the Validatricks server.
static NSString * const kAPIKeyHeaderName = @"x-api-key";

+ (NSString *)validatricksAPIKeyHeaderName {
  return kAPIKeyHeaderName;
}

+ (NSSet<NSData *> *)validatricksServerCertificates {
  return [NSSet setWithObjects:
          BZRValidatricksServerCertificateData(),
          BZRValidatricksHKServerCertificateData(),
          nil];
}

- (instancetype)init {
  return [self initWithAPIKey:kValidatricksAPIKey
           pinnedCertificates:[[self class] validatricksServerCertificates]];
}

- (instancetype)initWithAPIKey:(nullable NSString *)APIKey
            pinnedCertificates:(nullable NSSet<NSData *> *)pinnedCertificates {
  if (self = [super init]) {
    _APIKey = APIKey;
    _pinnedCertificates = pinnedCertificates;
  }
  return self;
}

- (FBRHTTPSessionConfiguration *)HTTPSessionConfiguration {
  return [[FBRHTTPSessionConfiguration alloc]
          initWithSessionConfiguration:[self sessionConfiguration]
          requestMarshalling:[self requestMarshalling]
          securityPolicy:[self securityPolicy]];
}

- (NSURLSessionConfiguration *)sessionConfiguration {
  NSURLSessionConfiguration *configuration =
      [NSURLSessionConfiguration defaultSessionConfiguration];
  configuration.URLCache = nil;
  configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
  return configuration;
}

- (FBRHTTPSessionRequestMarshalling *)requestMarshalling {
  FBRHTTPRequestParametersEncoding *parametersEncoding = $(FBRHTTPRequestParametersEncodingJSON);
  FBRHTTPRequestHeaders *headers =
      self.APIKey ? @{[[self class] validatricksAPIKeyHeaderName]: self.APIKey} : nil;
  return [[FBRHTTPSessionRequestMarshalling alloc] initWithParametersEncoding:parametersEncoding
                                                                      headers:headers];
}

- (FBRHTTPSessionSecurityPolicy *)securityPolicy {
  return self.pinnedCertificates.count ?
      [FBRHTTPSessionSecurityPolicy
       securityPolicyWithPinnedPublicKeysFromCertificates:self.pinnedCertificates] :
      [FBRHTTPSessionSecurityPolicy standardSecurityPolicy];
}

@end

NS_ASSUME_NONNULL_END
