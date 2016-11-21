// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsWithVariantsProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRProduct.h"
#import "BZRTestUtils.h"

SpecBegin(BZRProductsWithVariantsProvider)

__block id<BZRProductsProvider> underlyingProvider;
__block BZRProductsWithVariantsProvider *provider;

beforeEach(^{
  underlyingProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
  provider =
      [[BZRProductsWithVariantsProvider alloc] initWithUnderlyingProvider:underlyingProvider];
});

context(@"creating variants as products", ^{
  it(@"should err when underlying provider errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal error:error]);

    expect([provider fetchProductList]).will.sendError(error);
  });

  it(@"should complete when undelying provider completes", ^{
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal empty]);

    expect([provider fetchProductList]).will.complete();
  });

  it(@"should create variant product with nil variants property", ^{
    BZRProduct *product = BZRProductWithIdentifier(@"foo");
    product =
        [product modelByOverridingProperty:@keypath(product, variants) withValue:@[@"A"]];
    NSArray<BZRProduct *> *productList = @[product];
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal return:productList]);

    LLSignalTestRecorder *recorder = [[provider fetchProductList] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.matchValue(0, ^BOOL(NSArray<BZRProduct *> *productList) {
      BZRProduct *variant = [productList lt_filter:^BOOL(BZRProduct *product) {
        return [product.identifier isEqualToString:@"foo.Variant.A"];
      }].firstObject;
      return !variant.variants;
    });
  });

  it(@"should create products from the list of variants", ^{
    BZRProduct *firstProduct = BZRProductWithIdentifier(@"foo");
    firstProduct =
        [firstProduct modelByOverridingProperty:@keypath(firstProduct, variants)
                                      withValue:@[@"A", @"B"]];
    BZRProduct *secondProduct = BZRProductWithIdentifier(@"bar");
    secondProduct =
        [secondProduct modelByOverridingProperty:@keypath(secondProduct, variants)
                                       withValue:@[@"C", @"D"]];
    NSArray<BZRProduct *> *productList = @[firstProduct, secondProduct];
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal return:productList]);

    LLSignalTestRecorder *recorder = [[provider fetchProductList] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.matchValue(0, ^BOOL(NSArray<BZRProduct *> *productList) {
      NSSet<NSString *> *productsIdentifiers = [NSSet setWithArray:
          [productList valueForKey:@instanceKeypath(BZRProduct, identifier)]];
      return [productList count] == 6 &&
          [productsIdentifiers isEqualToSet:
           [NSSet setWithObjects:@"foo", @"foo.Variant.A", @"foo.Variant.B", @"bar",
            @"bar.Variant.C", @"bar.Variant.D", nil]];
    });
  });
});

SpecEnd
