// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocaleBasedVariantSelectorFactory.h"

#import <LTKit/NSFileManager+LTKit.h>

#import "BZRLocaleBasedVariantSelector.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRLocaleBasedVariantSelectorFactory)

__block NSFileManager *fileManager;
__block BZRLocaleBasedVariantSelectorFactory *factory;

beforeEach(^{
  fileManager = OCMClassMock([NSFileManager class]);
  factory =
      [[BZRLocaleBasedVariantSelectorFactory alloc] initWithFileManager:fileManager
       countryToTierPath:[LTPath pathWithPath:@"foo"]];
  });

context(@"creating products variant provider", ^{
  it(@"should return nil if file couldn't be loaded", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg setTo:error]]);

    NSError *returnedError;
    id<BZRProductsVariantSelector> selector =
        [factory productsVariantSelectorWithProductDictionary:@{} error:&returnedError];
    expect(selector).to.beNil();
    expect(returnedError.lt_isLTDomain).to.beTruthy();
    expect(returnedError.code).to.equal(BZRErrorCodeLoadingFileFailed);
    expect(returnedError.lt_underlyingError).to.equal(error);
  });

  it(@"should return nil when failed to deserialize raw data into JSON", ^{
    NSData *invalidData = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg anyObjectRef]]).andReturn(invalidData);

    NSError *returnedError;
    id<BZRProductsVariantSelector> selector =
        [factory productsVariantSelectorWithProductDictionary:@{} error:&returnedError];
    expect(selector).to.beNil();
    expect(returnedError.lt_isLTDomain).to.beTruthy();
    expect(returnedError.code).to.equal(BZRErrorCodeJSONDataDeserializationFailed);
  });

  it(@"should return not nil object", ^{
    NSData *data =
        [NSJSONSerialization dataWithJSONObject:@{@"foo": @"bar"} options:0 error:nil];
    OCMStub([fileManager lt_dataWithContentsOfFile:OCMOCK_ANY options:0
                                             error:[OCMArg anyObjectRef]]).andReturn(data);

    NSError *returnedError;
    id<BZRProductsVariantSelector> selector =
        [factory productsVariantSelectorWithProductDictionary:@{} error:&returnedError];
    expect(selector).toNot.beNil();
    expect(returnedError).to.beNil();
  });
});

SpecEnd
