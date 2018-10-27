// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocalProductsProvider.h"

#import <LTKit/NSFileManager+LTKit.h>

#import "BZRProduct.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRLocalProductsProvider)

context(@"fetching products", ^{
  __block id fileManager;
  __block BZRLocalProductsProvider *provider;

  beforeEach(^{
    LTPath *path = [LTPath pathWithPath:@"/path/to/json/file.json"];
    fileManager = OCMClassMock([NSFileManager class]);
    provider = [[BZRLocalProductsProvider alloc] initWithPath:path decryptionKey:nil
                                                  fileManager:fileManager];
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

  it(@"should send error when failed to deserialize JSON into BZRProduct list", ^{
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

context(@"fetching decrypted product list", ^{
  /// encrypted and compressed products json file.
  static char kSecuredJSONDataBytes[] =
      "\x6c\x92\xc8\xdf\x10\xb1\x9b\x9c\x8a\x27\x03\xd8\xe4\xd2\xef\xa6\x39\xad\x09\x00\x4b\x8a"
      "\x97\x7d\xd4\x0b\xf0\x94\xf5\xb6\xb6\xf9\xf8\x45\x4c\x7e\xcd\xbc\xb5\xa1\x85\x2b\xea\xe3"
      "\x10\xa1\xc4\xf9\xbd\x9d\x19\x9e\x55\xde\x21\xc4\x9c\x59\xb3\x6f\x13\xf0\xd8\x91\xed\x93"
      "\x37\xc1\xa7\xeb\xc1\x74\x2f\xfa\xf3\xde\xb4\xfc\x16\x7f\xfd\xd7\x0b\xce\x91\xfd\x9b\xd6"
      "\xfc\x04\x3a\xcd\x91\x20\x64\xfb\x19\xa4\x71\x63\x1d\xa4\xa2\xec\xe1\xd8\xe2\xc6\xa4\xef"
      "\xfb\x11\x5b\xa1\x04\xf3\x7a\x21\x7f\xc9\xfc\x2b\x9c\xac\x3f\x1a\x31\xba\x76\x6b\xc4\x0e"
      "\x8f\x38\x21\xd4\x3b\x33\xe0\xc4\xd9\xc1\x83\xfe\x21\xb9\xa0\xa3\x7d\xac\x6d\x03\x06\x6c"
      "\xde\x14\x62\x80\x90\xbb";

  __block NSFileManager *fileManager;

  beforeEach(^{
    fileManager = OCMClassMock([NSFileManager class]);
  });

  it(@"should raise exception if the decryption key length is invalid", ^{
    expect(^{
      auto __unused provider =
          [[BZRLocalProductsProvider alloc] initWithPath:OCMOCK_ANY decryptionKey:@"123456"
                                             fileManager:fileManager];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise exception if the decryption key is not a valid hex string", ^{
    expect(^{
      auto decryptionKey = @"123456789A123456789B123456789CDZ";
      auto __unused provider =
          [[BZRLocalProductsProvider alloc] initWithPath:OCMOCK_ANY decryptionKey:decryptionKey
                                             fileManager:fileManager];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should decrypt and deserialize correctly", ^{
    auto JSONData = [NSData dataWithBytes:kSecuredJSONDataBytes
                                   length:sizeof(kSecuredJSONDataBytes)];
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg anyObjectRef]]).andReturn(JSONData);
    auto decryptionKey = @"123456789A123456789B123456789CDE";
    auto provider = [[BZRLocalProductsProvider alloc] initWithPath:[LTPath pathWithPath:@"foo"]
                                                     decryptionKey:decryptionKey
                                                       fileManager:fileManager];

    auto recorder = [[provider fetchProductList] testRecorder];

    expect(recorder).will.matchValue(0, ^BOOL(NSArray<BZRProduct *> *products) {
      return [products[0].identifier isEqualToString:@"product1"] &&
          [products[1].identifier isEqualToString:@"product2"] &&
          products[0].isSubscribersOnly && products[1].isSubscribersOnly;
    });
    expect(recorder).will.complete();
  });

  it(@"should err if decoding failed", ^{
    kSecuredJSONDataBytes[0] = 'x';
    auto JSONData = [NSData dataWithBytes:kSecuredJSONDataBytes
                                   length:sizeof(kSecuredJSONDataBytes)];
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg setTo:nil]]).andReturn(JSONData);
    auto decryptionKey = @"123456789A123456789B123456789CDE";
    auto provider = [[BZRLocalProductsProvider alloc] initWithPath:[LTPath pathWithPath:@"foo"]
                                                     decryptionKey:decryptionKey
                                                       fileManager:fileManager];

    auto recorder = [[provider fetchProductList] testRecorder];

    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.code == LTErrorCodeCompressionFailed;
    });
  });
});

SpecEnd
