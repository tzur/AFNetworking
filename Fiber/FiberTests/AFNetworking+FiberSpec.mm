// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "AFNetworking+Fiber.h"

#import "FBRHTTPRequest.h"
#import "FBRHTTPSessionConfiguration.h"
#import "FBRHTTPSessionRequestMarshalling.h"
#import "FBRHTTPSessionSecurityPolicy.h"
#import "NSError+Fiber.h"
#import "NSErrorCodes+Fiber.h"

#pragma mark -
#pragma mark AFSecurityPolicy+Fiber
#pragma mark -

SpecBegin(AFSecurityPolicy_Fiber)

it(@"should return the correct security policy for standard security policy", ^{
  FBRHTTPSessionSecurityPolicy *fiberSecurityPolicy =
      [FBRHTTPSessionSecurityPolicy standardSecurityPolicy];
  AFSecurityPolicy *securityPolicy =
      [AFSecurityPolicy fbr_securityPolicyWithFiberSecurityPolicy:fiberSecurityPolicy];

  expect(securityPolicy).to.beKindOf([AFSecurityPolicy class]);
  expect(securityPolicy.SSLPinningMode).to.equal(AFSSLPinningModeNone);
  expect(securityPolicy.pinnedCertificates).to.beNil();
});

it(@"should return the correct security policy for security policy with pinned certificates", ^{
  NSSet<NSData *> *certificates =
      [NSSet setWithObjects:[@"Foo" dataUsingEncoding:NSUTF8StringEncoding], nil];
  FBRHTTPSessionSecurityPolicy *fiberSecurityPolicy =
      [FBRHTTPSessionSecurityPolicy securityPolicyWithPinnedCertificates:certificates];
  AFSecurityPolicy *securityPolicy =
      [AFSecurityPolicy fbr_securityPolicyWithFiberSecurityPolicy:fiberSecurityPolicy];

  expect(securityPolicy).to.beKindOf([AFSecurityPolicy class]);
  expect(securityPolicy.SSLPinningMode).to.equal(AFSSLPinningModeCertificate);
  expect(securityPolicy.pinnedCertificates).to.equal(certificates);
});

it(@"should return the correct security policy for security policy with pinned certificate keys", ^{
  NSSet<NSData *> *certificates =
      [NSSet setWithObjects:[@"Foo" dataUsingEncoding:NSUTF8StringEncoding], nil];
  FBRHTTPSessionSecurityPolicy *fiberSecurityPolicy =
      [FBRHTTPSessionSecurityPolicy
       securityPolicyWithPinnedPublicKeysFromCertificates:certificates];
  AFSecurityPolicy *securityPolicy =
      [AFSecurityPolicy fbr_securityPolicyWithFiberSecurityPolicy:fiberSecurityPolicy];

  expect(securityPolicy).to.beKindOf([AFSecurityPolicy class]);
  expect(securityPolicy.SSLPinningMode).to.equal(AFSSLPinningModePublicKey);
  expect(securityPolicy.pinnedCertificates).to.equal(certificates);
});

SpecEnd

#pragma mark -
#pragma mark AFHTTPRequestSerializaer+Fiber
#pragma mark -

SpecBegin(AFHTTPRequestSerializaer_Fiber)

context(@"serializer construction", ^{
  it(@"should return the correct serializer for request marshalling with URL query encoding", ^{
    FBRHTTPSessionRequestMarshalling *requestMarshlling =
        [[FBRHTTPSessionRequestMarshalling alloc]
         initWithParametersEncoding:$(FBRHTTPRequestParametersEncodingURLQuery) headers:nil];
    AFHTTPRequestSerializer *serializer =
        [AFHTTPRequestSerializer fbr_serializerWithFiberRequestMarshalling:requestMarshlling];

    expect(serializer).to.beInstanceOf([AFHTTPRequestSerializer class]);
  });

  it(@"should return the correct serializer for request marshalling with JSON encoding", ^{
    FBRHTTPSessionRequestMarshalling *requestMarshlling =
        [[FBRHTTPSessionRequestMarshalling alloc]
         initWithParametersEncoding:$(FBRHTTPRequestParametersEncodingJSON) headers:nil];
    AFHTTPRequestSerializer *serializer =
        [AFHTTPRequestSerializer fbr_serializerWithFiberRequestMarshalling:requestMarshlling];

    expect(serializer).to.beInstanceOf([AFJSONRequestSerializer class]);
  });

  it(@"should append the HTTP headers specified by the request marshalling", ^{
    FBRHTTPSessionRequestMarshalling *requestMarshlling =
        [[FBRHTTPSessionRequestMarshalling alloc]
         initWithParametersEncoding:$(FBRHTTPRequestParametersEncodingURLQuery)
         headers:@{@"Foo": @"Bar"}];
    AFHTTPRequestSerializer *serializer =
        [AFHTTPRequestSerializer fbr_serializerWithFiberRequestMarshalling:requestMarshlling];

    expect(serializer.HTTPRequestHeaders[@"Foo"]).to.equal(@"Bar");
  });
});

context(@"serializer for request", ^{
  __block id defaultSerializer;
  __block AFHTTPRequestSerializer *defaultSerializerCopy;

  beforeEach(^{
    // The use of strict mock for the default serializers helps to ensure that it is not changed by
    // the method.
    defaultSerializer = OCMStrictClassMock([AFHTTPRequestSerializer class]);
    defaultSerializerCopy = [AFHTTPRequestSerializer serializer];
    OCMStub([defaultSerializer copy]).andReturn(defaultSerializerCopy);
  });

  it(@"should return the default serializer if parameters encoding and headers nil", ^{
    FBRHTTPRequest *request =
        [[FBRHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                     method:$(FBRHTTPRequestMethodGet)];
    AFHTTPRequestSerializer *serializer =
        [AFHTTPRequestSerializer fbr_serializerForRequest:request
                                    withDefaultSerializer:defaultSerializer];

    expect(serializer).to.beIdenticalTo(defaultSerializerCopy);
  });

  it(@"should add the request headers to the returned serializer", ^{
    FBRHTTPRequest *request =
        [[FBRHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                     method:$(FBRHTTPRequestMethodGet) parameters:nil
                         parametersEncoding:nil headers:@{@"Foo": @"Bar"}];
    AFHTTPRequestSerializer *serializer =
        [AFHTTPRequestSerializer fbr_serializerForRequest:request
                                    withDefaultSerializer:defaultSerializer];

    expect(serializer).to.beIdenticalTo(defaultSerializerCopy);
    expect(serializer.HTTPRequestHeaders[@"Foo"]).to.equal(@"Bar");
    OCMVerifyAll(defaultSerializer);
  });

  it(@"should return a serializer matching the request parameters encoding", ^{
    FBRHTTPRequest *request =
        [[FBRHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                     method:$(FBRHTTPRequestMethodGet) parameters:@{}
                         parametersEncoding:$(FBRHTTPRequestParametersEncodingJSON) headers:nil];
    AFHTTPRequestSerializer *serializer =
        [AFHTTPRequestSerializer fbr_serializerForRequest:request
                                    withDefaultSerializer:defaultSerializer];

    expect(serializer).to.beKindOf([AFJSONRequestSerializer class]);
  });

  it(@"should return a serializer matching the request parameters encoding with headers", ^{
    FBRHTTPRequest *request =
        [[FBRHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                     method:$(FBRHTTPRequestMethodGet) parameters:@{}
                         parametersEncoding:$(FBRHTTPRequestParametersEncodingJSON)
                                    headers:@{@"Foo": @"Bar"}];
    AFHTTPRequestSerializer *serializer =
        [AFHTTPRequestSerializer fbr_serializerForRequest:request
                                    withDefaultSerializer:defaultSerializer];

    expect(serializer).to.beKindOf([AFJSONRequestSerializer class]);
    expect(serializer.HTTPRequestHeaders[@"Foo"]).to.equal(@"Bar");
  });

  it(@"should override serializer headers with request headers", ^{
    [defaultSerializerCopy setValue:@"Baz" forHTTPHeaderField:@"Foo"];
    FBRHTTPRequest *request =
        [[FBRHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                     method:$(FBRHTTPRequestMethodGet) parameters:nil
                         parametersEncoding:nil headers:@{@"Foo": @"Bar"}];
    AFHTTPRequestSerializer *serializer =
        [AFHTTPRequestSerializer fbr_serializerForRequest:request
                                    withDefaultSerializer:defaultSerializer];

    expect(serializer).to.beIdenticalTo(defaultSerializerCopy);
    expect(serializer.HTTPRequestHeaders[@"Foo"]).to.equal(@"Bar");
  });
});

context(@"request serialization", ^{
  __block FBRHTTPRequest *request;
  __block AFHTTPRequestSerializer *serializer;

  beforeEach(^{
    request = [[FBRHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                           method:$(FBRHTTPRequestMethodGet)
                                       parameters:@{@"foo": @"bar"} parametersEncoding:nil
                                          headers:nil];
    serializer = [AFHTTPRequestSerializer serializer];
  });

  it(@"should serialize the request with its parameters", ^{
    NSError *error;
    NSURLRequest *serializedRequest = [serializer fbr_serializedRequestWithRequest:request
                                                                             error:&error];
    expect(serializedRequest).toNot.beNil();
    expect(error).to.beNil();
    expect(serializedRequest.URL).to.equal([NSURL URLWithString:@"http://foo.bar?foo=bar"]);
  });

  context(@"serialization error", ^{
    __block id serializerMock;
    __block NSError *serializationError;

    beforeEach(^{
      serializationError = [NSError errorWithDomain:AFURLRequestSerializationErrorDomain
                                               code:NSURLErrorUnknown userInfo:nil];
      serializerMock = OCMPartialMock(serializer);
      OCMStub([serializerMock requestWithMethod:OCMOCK_ANY URLString:OCMOCK_ANY
                                     parameters:OCMOCK_ANY
                                          error:[OCMArg setTo:serializationError]]);
    });

    afterEach(^{
      serializerMock = nil;
    });

    it(@"should wrap and forward the serialization error if error is not nil", ^{
      NSError *error;
      NSURLRequest *serializedRequest = [serializer fbr_serializedRequestWithRequest:request
                                                                               error:&error];

      expect(serializedRequest).to.beNil();
      expect(error.domain).to.equal(kLTErrorDomain);
      expect(error.code).to.equal(FBRErrorCodeHTTPRequestSerializationFailed);
      expect(error.fbr_HTTPRequest).to.equal(request);
      expect(error.lt_underlyingError).to.equal(serializationError);
    });

    it(@"should return nil on error even if error is not nil", ^{
      NSURLRequest *serializedRequest = [serializerMock fbr_serializedRequestWithRequest:request
                                                                                   error:nil];
      expect(serializedRequest).to.beNil();
    });
  });
});

SpecEnd

#pragma mark -
#pragma mark AFHTTPSessionManager+Fiber
#pragma mark -

SpecBegin(AFHTTPSessionManager_Fiber)

__block NSURLSessionConfiguration *sessionConfiguration;
__block FBRHTTPSessionRequestMarshalling *requestMarshalling;
__block FBRHTTPSessionSecurityPolicy *securityPolicy;
__block FBRHTTPSessionConfiguration *configuration;

beforeEach(^{
  sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
  requestMarshalling = [[FBRHTTPSessionRequestMarshalling alloc] init];
  NSSet<NSData *> *certificates =
      [NSSet setWithObject:[@"foo" dataUsingEncoding:NSUTF8StringEncoding]];
  securityPolicy = [FBRHTTPSessionSecurityPolicy securityPolicyWithPinnedCertificates:certificates];
  configuration =
      [[FBRHTTPSessionConfiguration alloc] initWithSessionConfiguration:sessionConfiguration
                                                     requestMarshalling:requestMarshalling
                                                         securityPolicy:securityPolicy];
});

it(@"should create a session manager with the specified base URL and configuration", ^{
  NSURL *baseURL = [NSURL URLWithString:@"https://foo.bar"];
  AFHTTPSessionManager *sessionManager =
      [AFHTTPSessionManager fbr_sessionManagerWithBaseURL:baseURL fiberConfiguration:configuration];
  AFHTTPRequestSerializer *expectedSerializer =
      [AFHTTPRequestSerializer fbr_serializerWithFiberRequestMarshalling:requestMarshalling];
  AFSecurityPolicy *expectedSecurityPolicy =
      [AFSecurityPolicy fbr_securityPolicyWithFiberSecurityPolicy:securityPolicy];

  expect(sessionManager.baseURL).to.equal(baseURL);
  expect(sessionManager.requestSerializer).to.beInstanceOf([expectedSerializer class]);
  expect(sessionManager.requestSerializer.HTTPRequestHeaders).to
      .equal(expectedSerializer.HTTPRequestHeaders);
  expect(sessionManager.securityPolicy.SSLPinningMode).to.
      equal(expectedSecurityPolicy.SSLPinningMode);
  expect(sessionManager.securityPolicy.pinnedCertificates).to
      .equal(expectedSecurityPolicy.pinnedCertificates);
  expect(sessionManager.responseSerializer).to.beInstanceOf([AFHTTPResponseSerializer class]);
});

it(@"should raise exception if initialized with SSL pinning policy and non-HTTPS base URL", ^{
  NSURL *baseURL = [NSURL URLWithString:@"http://foo.bar"];
  expect(^{
    [AFHTTPSessionManager fbr_sessionManagerWithBaseURL:baseURL fiberConfiguration:configuration];
  }).to.raise(NSInternalInconsistencyException);
});

it(@"should raise exception if initialized with SSL pinning policy and no base URL", ^{
  expect(^{
    [AFHTTPSessionManager fbr_sessionManagerWithBaseURL:nil fiberConfiguration:configuration];
  }).to.raise(NSInternalInconsistencyException);
});

SpecEnd
