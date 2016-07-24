// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocalJSONProductsProvider.h"

#import <LTKit/LTPath.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRLocalJSONProductsProvider)

context(@"fetching products", ^{
  __block id fileManager;
  __block BZRLocalJSONProductsProvider *provider;

  beforeEach(^{
    LTPath *path = [LTPath pathWithPath:@"/path/to/json/file.json"];
    fileManager = OCMClassMock([NSFileManager class]);
    provider = [[BZRLocalJSONProductsProvider alloc] initWithPath:path fileManager:fileManager];
  });

  afterEach(^{
    fileManager = nil;
  });

  it(@"should send error when failed to load file contents", ^{
    NSError *errorMock = OCMClassMock([NSError class]);
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg setTo:errorMock]]);

    RACSignal *signal = [provider fetchJSONProductList];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return errorMock == error;
    });
  });

  it(@"should send error when failed to deserialize json", ^{
    const char *string = "foo";
    NSData *invalidData = [NSData dataWithBytes:string length:strlen(string)];

    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg setTo:nil]]).andReturn(invalidData);

    RACSignal *signal = [provider fetchJSONProductList];

    expect(signal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeJSONDataDeserializationFailed;
    });
  });

  it(@"should complete successfully when no error occurred", ^{
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:@{@"foo": @"bar"} options:0
                                                         error:NULL];
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg setTo:nil]]).andReturn(JSONData);

    RACSignal *signal = [provider fetchJSONProductList];

    expect(signal).will.sendValuesWithCount(1);
    expect(signal).will.complete();
  });
});

SpecEnd
