// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPClient+Validatricks.h"

#import <Fiber/FBRHTTPRequest.h>
#import <Fiber/FBRHTTPSessionConfiguration.h>
#import <Fiber/FBRHTTPSessionRequestMarshalling.h>
#import <Fiber/FBRHTTPSessionSecurityPolicy.h>
#import <Fiber/RACSignal+Fiber.h>

NS_ASSUME_NONNULL_BEGIN

@implementation FBRHTTPClient (Validatricks)

/// HTTP header name to use for API key in case API key is required by the Validatricks server.
static NSString * const kAPIKeyHeaderName = @"x-api-key";

+ (NSString *)bzr_validatricksAPIKeyHeaderName {
  return kAPIKeyHeaderName;
}

+ (instancetype)bzr_validatricksClientWithServerURL:(NSURL *)serverURL
                                             APIKey:(nullable NSString *)APIKey
                                 pinnedCertificates:(nullable NSSet<NSData *> *)pinnedCertificates {
  FBRHTTPSessionConfiguration *configuration =
      [self bzr_configurationForValidatricksClientWithAPIKey:APIKey
                                          pinnedCertificates:pinnedCertificates];
  return [[self class] clientWithSessionConfiguration:configuration baseURL:serverURL];
}

+ (FBRHTTPSessionConfiguration *)
    bzr_configurationForValidatricksClientWithAPIKey:(nullable NSString *)APIKey
    pinnedCertificates:(nullable NSSet<NSData *> *)pinnedCertificates {
  return [[FBRHTTPSessionConfiguration alloc]
          initWithSessionConfiguration:[self bzr_sessionConfigurationForValidatricksClient]
          requestMarshalling:[self bzr_requestMarshallingWithAPIKey:APIKey]
          securityPolicy:[self bzr_securityPolicyWithPinnedCertificates:pinnedCertificates]];
}

+ (NSURLSessionConfiguration *)bzr_sessionConfigurationForValidatricksClient {
  NSURLSessionConfiguration *configuration =
      [NSURLSessionConfiguration defaultSessionConfiguration];
  configuration.URLCache = nil;
  configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
  return configuration;
}

+ (FBRHTTPSessionRequestMarshalling *)bzr_requestMarshallingWithAPIKey:
    (nullable NSString *)APIKey {
  FBRHTTPRequestParametersEncoding *parametersEncoding = $(FBRHTTPRequestParametersEncodingJSON);
  FBRHTTPRequestHeaders *headers =
      APIKey ? @{[self bzr_validatricksAPIKeyHeaderName]: APIKey} : nil;
  return [[FBRHTTPSessionRequestMarshalling alloc] initWithParametersEncoding:parametersEncoding
                                                                      headers:headers];
}

+ (FBRHTTPSessionSecurityPolicy *)bzr_securityPolicyWithPinnedCertificates:
    (nullable NSSet<NSData *> *)pinnedCertificates {
  return pinnedCertificates ?
      [FBRHTTPSessionSecurityPolicy securityPolicyWithPinnedCertificates:pinnedCertificates] :
      [FBRHTTPSessionSecurityPolicy standardSecurityPolicy];
}

@end

NS_ASSUME_NONNULL_END
