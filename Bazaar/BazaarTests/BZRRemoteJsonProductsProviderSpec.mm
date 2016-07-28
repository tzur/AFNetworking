// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRRemoteJSONProductsProvider.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/RACSignal+Fiber.h>

#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRRemoteJSONProductsProvider)

context(@"fetching JSON products list", ^{
  __block NSURL *URL;
  __block id client;

  __block BZRRemoteJSONProductsProvider *provider;

  beforeEach(^{
    URL = [NSURL URLWithString:@"http://path/to/foo/productsList.json"];
    client = OCMClassMock([FBRHTTPClient class]);

    provider = [[BZRRemoteJSONProductsProvider alloc] initWithURL:URL HTTPClient:client];
  });

  afterEach(^{
    client = nil;
  });

  it(@"should send error when GET failed", ^{
    NSError *errorMock = OCMClassMock([NSError class]);
    RACSignal *httpSignal = [RACSignal error:errorMock];
    OCMStub([client GET:OCMOCK_ANY withParameters:OCMOCK_ANY]).andReturn(httpSignal);

    RACSignal *signal = [provider fetchJSONProductList];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error == errorMock;
    });
  });

  it(@"should send JSON array after successful GET and deserialize operations", ^{
    NSArray *array = @[@"someString"];
    RACSignal *expectedSignal = [RACSignal return:array];
    RACSignal *signalMock = OCMClassMock([RACSignal class]);
    OCMStub([signalMock fbr_deserializeJSON]).andReturn(expectedSignal);
    OCMStub([client GET:OCMOCK_ANY withParameters:OCMOCK_ANY]).andReturn(signalMock);

    RACSignal *signal = [provider fetchJSONProductList];

    expect(signal).will.sendValues(@[array]);
    expect(signal).will.complete();
  });

  it(@"should send error when deserialized object is not an array", ^{
    RACSignal *expectedSignal = [RACSignal return:@{}];
    RACSignal *signalMock = OCMClassMock([RACSignal class]);
    OCMStub([signalMock fbr_deserializeJSON]).andReturn(expectedSignal);
    OCMStub([client GET:OCMOCK_ANY withParameters:OCMOCK_ANY]).andReturn(signalMock);

    RACSignal *signal = [provider fetchJSONProductList];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeJSONDataDeserializationFailed;
    });
  });
});

SpecEnd
