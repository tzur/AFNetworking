// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksSessionConfigurationProvider.h"

#import <Fiber/FBRHTTPSessionConfiguration.h>
#import <Fiber/FBRHTTPSessionRequestMarshalling.h>
#import <Fiber/FBRHTTPSessionSecurityPolicy.h>

SpecBegin(BZRValidatricksSessionConfigurationProvider)

__block NSURL *serverURL;
__block NSString *APIKey;
__block NSSet<NSData *> *certificates;

beforeEach(^{
  serverURL = [NSURL URLWithString:@"https://foo.bar"];
  APIKey = @"foo";
  certificates = [NSSet setWithObject:[@"bar" dataUsingEncoding:NSUTF8StringEncoding]];
});

it(@"should configure the session to avoid caching", ^{
  BZRValidatricksSessionConfigurationProvider *configurationProvider =
      [[BZRValidatricksSessionConfigurationProvider alloc] init];
  FBRHTTPSessionConfiguration *sessionConfiguration =
      [configurationProvider HTTPSessionConfiguration];

  expect(sessionConfiguration.sessionConfiguration.URLCache).to.beNil();
  expect(sessionConfiguration.sessionConfiguration.requestCachePolicy).to
      .equal(NSURLRequestReloadIgnoringLocalCacheData);
});

it(@"should configure the session to use JSON serialization for request parameters", ^{
  BZRValidatricksSessionConfigurationProvider *configurationProvider =
      [[BZRValidatricksSessionConfigurationProvider alloc] init];
  FBRHTTPSessionConfiguration *sessionConfiguration =
      [configurationProvider HTTPSessionConfiguration];

  expect(sessionConfiguration.requestMarshalling.parametersEncoding).to
      .equal($(FBRHTTPRequestParametersEncodingJSON));
});

it(@"should configure the session to add the given API key as HTTP header", ^{
  BZRValidatricksSessionConfigurationProvider *configurationProvider =
      [[BZRValidatricksSessionConfigurationProvider alloc] initWithAPIKey:APIKey
                                                       pinnedCertificates:nil];
  FBRHTTPSessionConfiguration *sessionConfiguration =
      [configurationProvider HTTPSessionConfiguration];

  expect(sessionConfiguration.requestMarshalling.headers[@"x-api-key"]).to.equal(APIKey);
});

it(@"should configure the session with standard security policy if nil certificates are "
   "provided", ^{
  BZRValidatricksSessionConfigurationProvider *configurationProvider =
      [[BZRValidatricksSessionConfigurationProvider alloc] initWithAPIKey:nil
                                                       pinnedCertificates:nil];
  FBRHTTPSessionConfiguration *sessionConfiguration =
      [configurationProvider HTTPSessionConfiguration];

  expect(sessionConfiguration.securityPolicy).to
      .equal([FBRHTTPSessionSecurityPolicy standardSecurityPolicy]);
});

it(@"should configure the session with certificate pinning if certificates are provided", ^{
  BZRValidatricksSessionConfigurationProvider *configurationProvider =
      [[BZRValidatricksSessionConfigurationProvider alloc] initWithAPIKey:APIKey
                                                       pinnedCertificates:certificates];
  FBRHTTPSessionConfiguration *sessionConfiguration =
      [configurationProvider HTTPSessionConfiguration];

  expect(sessionConfiguration.securityPolicy).to.equal(
      [FBRHTTPSessionSecurityPolicy securityPolicyWithPinnedPublicKeysFromCertificates:certificates]
  );
});

SpecEnd
