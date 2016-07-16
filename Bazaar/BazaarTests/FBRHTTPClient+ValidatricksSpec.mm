// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPClient+Validatricks.h"

#import <Fiber/FBRHTTPSessionConfiguration.h>
#import <Fiber/FBRHTTPSessionRequestMarshalling.h>
#import <Fiber/FBRHTTPSessionSecurityPolicy.h>

/// Fake HTTP client that records the session configuration that was received on initialization.
@interface BZRFakeHTTPClient : FBRHTTPClient

/// Session configuration that was received on initialization
@property (strong, nonatomic) FBRHTTPSessionConfiguration *configuration;

@end

@implementation BZRFakeHTTPClient

+ (instancetype)clientWithSessionConfiguration:(FBRHTTPSessionConfiguration *)configuration
                                       baseURL:(NSURL *)baseURL {
  BZRFakeHTTPClient *client = [super clientWithSessionConfiguration:configuration baseURL:baseURL];
  client.configuration = configuration;
  return client;
}

@end

SpecBegin(FBRHTTPClient_Validatricks)

__block NSURL *serverURL;
__block NSString *APIKey;
__block NSSet<NSData *> *certificates;

beforeEach(^{
  serverURL = [NSURL URLWithString:@"https://foo.bar"];
  APIKey = @"foo";
  certificates = [NSSet setWithObject:[@"bar" dataUsingEncoding:NSUTF8StringEncoding]];
});

it(@"should create a client using the given server url as base url", ^{
  BZRFakeHTTPClient *client = [BZRFakeHTTPClient bzr_validatricksClientWithServerURL:serverURL
                                                                              APIKey:nil
                                                                  pinnedCertificates:nil];

  expect(client.baseURL).to.equal(serverURL);
});

it(@"should configure the session to avoid caching", ^{
  BZRFakeHTTPClient *client = [BZRFakeHTTPClient bzr_validatricksClientWithServerURL:serverURL
                                                                              APIKey:nil
                                                                  pinnedCertificates:nil];

  expect(client.configuration.sessionConfiguration.URLCache).to.beNil();
  expect(client.configuration.sessionConfiguration.requestCachePolicy).to
      .equal(NSURLRequestReloadIgnoringLocalCacheData);
});


it(@"should configure the session to use JSON serialization for request parameters", ^{
  BZRFakeHTTPClient *client = [BZRFakeHTTPClient bzr_validatricksClientWithServerURL:serverURL
                                                                              APIKey:nil
                                                                  pinnedCertificates:nil];

  expect(client.configuration.requestMarshalling.parametersEncoding).to
      .equal($(FBRHTTPRequestParametersEncodingJSON));
});

it(@"should configure the session to add the given API key as HTTP headers", ^{
  BZRFakeHTTPClient *client = [BZRFakeHTTPClient bzr_validatricksClientWithServerURL:serverURL
                                                                              APIKey:APIKey
                                                                  pinnedCertificates:nil];

  expect(client.configuration.requestMarshalling.headers[@"x-api-key"]).to.equal(APIKey);
});

it(@"should configure the session with standard security policy if no certificates are provided", ^{
  BZRFakeHTTPClient *client = [BZRFakeHTTPClient bzr_validatricksClientWithServerURL:serverURL
                                                                              APIKey:nil
                                                                  pinnedCertificates:nil];

  expect(client.configuration.securityPolicy).to
      .equal([FBRHTTPSessionSecurityPolicy standardSecurityPolicy]);
});

it(@"should configure the session with certificate pinning if certificates are provided", ^{
  BZRFakeHTTPClient *client = [BZRFakeHTTPClient bzr_validatricksClientWithServerURL:serverURL
                                                                              APIKey:nil
                                                                  pinnedCertificates:certificates];

  expect(client.configuration.securityPolicy).to
      .equal([FBRHTTPSessionSecurityPolicy securityPolicyWithPinnedCertificates:certificates]);
});

SpecEnd
