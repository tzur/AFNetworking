// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPSessionConfiguration.h"

#import "FBRHTTPSessionRequestMarshalling.h"
#import "FBRHTTPSEssionSecurityPolicy.h"

SpecBegin(FBRHTTPSessionConfiguration)

__block NSURLSessionConfiguration *sessionConfiguration;
__block FBRHTTPSessionRequestMarshalling *requestMarshalling;
__block FBRHTTPSessionSecurityPolicy *securityPolicy;

beforeEach(^{
  sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
  requestMarshalling = [[FBRHTTPSessionRequestMarshalling alloc] init];
  securityPolicy = [FBRHTTPSessionSecurityPolicy standardSecurityPolicy];
});

context(@"default initialization", ^{
  it(@"should initialize with default configuration", ^{
    FBRHTTPSessionConfiguration *configuration = [[FBRHTTPSessionConfiguration alloc] init];

    expect(configuration.sessionConfiguration).
        to.equal([NSURLSessionConfiguration defaultSessionConfiguration]);
    expect(configuration.requestMarshalling).
        to.equal([[FBRHTTPSessionRequestMarshalling alloc] init]);
    expect(configuration.securityPolicy).
        to.equal([FBRHTTPSessionSecurityPolicy standardSecurityPolicy]);
  });
});

context(@"initialization with parameters", ^{
  it(@"should initialize with the given parameters", ^{
    FBRHTTPSessionConfiguration *configuration =
        [[FBRHTTPSessionConfiguration alloc] initWithSessionConfiguration:sessionConfiguration
                                                       requestMarshalling:requestMarshalling
                                                           securityPolicy:securityPolicy];

    expect(configuration.sessionConfiguration).to.equal(sessionConfiguration);
    expect(configuration.requestMarshalling).to.equal(requestMarshalling);
    expect(configuration.securityPolicy).to.equal(securityPolicy);
  });
});

context(@"session configuration property", ^{
  it(@"should make a copy of the provided session configuration to prevent mutability", ^{
    sessionConfiguration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    FBRHTTPSessionConfiguration *configuration =
        [[FBRHTTPSessionConfiguration alloc] initWithSessionConfiguration:sessionConfiguration
                                                       requestMarshalling:requestMarshalling
                                                           securityPolicy:securityPolicy];
    sessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

    expect(configuration.sessionConfiguration.requestCachePolicy).
        to.equal(NSURLRequestUseProtocolCachePolicy);
  });

  it(@"should return a copy of the session configuration to prevent mutability", ^{
    sessionConfiguration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    FBRHTTPSessionConfiguration *configuration =
        [[FBRHTTPSessionConfiguration alloc] initWithSessionConfiguration:sessionConfiguration
                                                       requestMarshalling:requestMarshalling
                                                           securityPolicy:securityPolicy];
    NSURLSessionConfiguration *retrievedSessionConfiguration = configuration.sessionConfiguration;
    retrievedSessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

    expect(configuration.sessionConfiguration.requestCachePolicy).
        to.equal(NSURLRequestUseProtocolCachePolicy);
  });
});

context(@"equality", ^{
  it(@"should inidcate that two identical objects are equal", ^{
    FBRHTTPSessionConfiguration *configuration = [[FBRHTTPSessionConfiguration alloc] init];
    FBRHTTPSessionConfiguration *anotherConfiguration = [[FBRHTTPSessionConfiguration alloc] init];

    expect([configuration isEqual:anotherConfiguration]).to.beTruthy();
  });

  it(@"should return the same hash for identical objects", ^{
    FBRHTTPSessionConfiguration *configuration = [[FBRHTTPSessionConfiguration alloc] init];
    FBRHTTPSessionConfiguration *anotherConfiguration = [[FBRHTTPSessionConfiguration alloc] init];

    expect(configuration.hash).to.equal(anotherConfiguration.hash);
  });

  it(@"should indicate that two non identical objects are not equal", ^{
    FBRHTTPSessionConfiguration *configuration = [[FBRHTTPSessionConfiguration alloc] init];
    FBRHTTPSessionConfiguration *anotherConfiguration =
        [[FBRHTTPSessionConfiguration alloc]
         initWithSessionConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]
         requestMarshalling:[[FBRHTTPSessionRequestMarshalling alloc] init]
         securityPolicy:[FBRHTTPSessionSecurityPolicy standardSecurityPolicy]];

    expect([configuration isEqual:anotherConfiguration]).to.beFalsy();
  });
});

context(@"copying", ^{
  it(@"should return a configuration identical to the copied configuration", ^{
    FBRHTTPSessionConfiguration *configuration = [[FBRHTTPSessionConfiguration alloc] init];
    FBRHTTPSessionConfiguration *configurationCopy = [configuration copy];

    expect(configuration).to.equal(configurationCopy);
  });
});

SpecEnd
