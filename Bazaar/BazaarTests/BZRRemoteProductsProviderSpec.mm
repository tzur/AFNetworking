// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRRemoteProductsProvider.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/FBRHTTPResponse.h>
#import <Fiber/RACSignal+Fiber.h>
#import <FiberTestUtils/FBRHTTPTestUtils.h>
#import <LTKit/LTProgress.h>

#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRRemoteProductsProvider)

context(@"fetching JSON products list", ^{
  __block NSURL *URL;
  __block id client;
  __block BZRRemoteProductsProvider *provider;

  beforeEach(^{
    URL = [NSURL URLWithString:@"http://path/to/foo/productsList.json"];
    client = OCMClassMock([FBRHTTPClient class]);

    provider = [[BZRRemoteProductsProvider alloc] initWithURL:URL HTTPClient:client];
  });

  it(@"should call GET method of HTTPClient", ^{
    [provider fetchProductList];

    OCMVerify([client GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY]);
  });

  it(@"should send error when GET failed", ^{
    NSError *errorMock = OCMClassMock([NSError class]);
    RACSignal *errorSignal = [RACSignal error:errorMock];
    OCMStub([client GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
        .andReturn(errorSignal);

    RACSignal *signal = [provider fetchProductList];

    expect(signal).will.sendError(errorMock);
  });

  it(@"should send error when failed to deserialize JSON into BZRProduct", ^{
    NSArray *JSONArray = @[@{@"foo": @"bar"}, @{@"bar": @"baz"}];
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSONArray options:0 error:NULL];
    auto response = FBRFakeHTTPResponse(@"http://foo.bar", 200, nil, JSONData);
    LTProgress<FBRHTTPResponse *> *progress = OCMClassMock([LTProgress class]);
    OCMStub([progress result]).andReturn(response);
    OCMStub([client GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
        .andReturn([RACSignal return:progress]);

    RACSignal *signal = [provider fetchProductList];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeModelJSONDeserializationFailed;
    });
  });

  it(@"should send BZRProduct array after successful GET and deserialize operations", ^{
    BZRProduct *product = BZRProductWithIdentifier(@"foo");
    NSArray *JSONArray = [MTLJSONAdapter JSONArrayFromModels:@[product, product]];
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSONArray options:0 error:NULL];
    auto response = FBRFakeHTTPResponse(@"http://foo.bar", 200, nil, JSONData);
    OCMStub([response content]).andReturn(JSONData);
    LTProgress<FBRHTTPResponse *> *progress = OCMClassMock([LTProgress class]);
    OCMStub([progress result]).andReturn(response);
    OCMStub([client GET:OCMOCK_ANY withParameters:OCMOCK_ANY headers:OCMOCK_ANY])
        .andReturn([RACSignal return:progress]);

    LLSignalTestRecorder *recorder = [[provider fetchProductList] testRecorder];

    expect(recorder).will.sendValues(@[@[product, product]]);
    expect(recorder).will.complete();
  });
});

SpecEnd
