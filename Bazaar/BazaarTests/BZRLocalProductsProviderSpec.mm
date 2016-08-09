// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocalProductsProvider.h"

#import <LTKit/NSFileManager+LTKit.h>

#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRLocalProductsProvider)

context(@"fetching products", ^{
  __block id fileManager;
  __block BZRLocalProductsProvider *provider;

  beforeEach(^{
    LTPath *path = [LTPath pathWithPath:@"/path/to/json/file.json"];
    fileManager = OCMClassMock([NSFileManager class]);
    provider = [[BZRLocalProductsProvider alloc] initWithPath:path fileManager:fileManager];
  });

  it(@"should send error when failed to load file contents", ^{
    NSError *errorMock = OCMClassMock([NSError class]);
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg setTo:errorMock]]);

    RACSignal *signal = [provider fetchProductList];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return errorMock == error;
    });
  });

  it(@"should send error when failed to deserialize raw data into JSON", ^{
    NSData *invalidData = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];

    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg setTo:nil]]).andReturn(invalidData);

    RACSignal *signal = [provider fetchProductList];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeJSONDataDeserializationFailed;
    });
  });

  it(@"should send error when failed to deserialize JSON into BZRProduct", ^{
    NSDictionary *JSONDictionary = @{@"foo": @"bar"};
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSONDictionary options:0 error:NULL];
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg setTo:nil]]).andReturn(JSONData);

    RACSignal *signal = [provider fetchProductList];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeModelJSONDeserializationFailed;
    });
  });

  it(@"should deserialize correctly", ^{
    BZRProduct *product = BZRProductWithIdentifier(@"foo");
    NSArray *JSONArray = [MTLJSONAdapter JSONArrayFromModels:@[product, product]];
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:JSONArray options:0 error:NULL];
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg setTo:nil]]).andReturn(JSONData);

    LLSignalTestRecorder *recorder = [[provider fetchProductList] testRecorder];

    expect(recorder).will.sendValues(@[@[product, product]]);
    expect(recorder).will.complete();
  });
});

SpecEnd
