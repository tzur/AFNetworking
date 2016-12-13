// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsWithDiscountsProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRProduct.h"
#import "BZRTestUtils.h"

SpecBegin(BZRProductsWithDiscountsProvider)

__block id<BZRProductsProvider> underlyingProvider;
__block BZRProductsWithDiscountsProvider *provider;

beforeEach(^{
  underlyingProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
  provider =
      [[BZRProductsWithDiscountsProvider alloc] initWithUnderlyingProvider:underlyingProvider];
});

context(@"creating discounts as products", ^{
  it(@"should err when underlying provider errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal error:error]);

    expect([provider fetchProductList]).will.sendError(error);
  });

  it(@"should complete when undelying provider completes", ^{
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal empty]);

    expect([provider fetchProductList]).will.complete();
  });

  it(@"should not create discounted products for a product without discounts", ^{
    BZRProduct *product = BZRProductWithIdentifier(@"foo");
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal return:@[product]]);

    LLSignalTestRecorder *recorder = [[provider fetchProductList] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.matchValue(0, ^BOOL(NSArray<BZRProduct *> *productList) {
      return productList.count == 1 && [productList.firstObject.identifier isEqualToString:@"foo"];
    });
  });

  it(@"should create discount product with nil discounts property", ^{
    BZRProduct *product = BZRProductWithIdentifier(@"foo");
    product =
        [product modelByOverridingProperty:@keypath(product, discountedProducts)
                                 withValue:@[@"foo.bar"]];
    NSArray<BZRProduct *> *productList = @[product];
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal return:productList]);

    LLSignalTestRecorder *recorder = [[provider fetchProductList] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.matchValue(0, ^BOOL(NSArray<BZRProduct *> *productList) {
      BZRProduct *variant = [productList lt_filter:^BOOL(BZRProduct *product) {
        return [product.identifier isEqualToString:@"foo.bar"];
      }].firstObject;
      return !variant.discountedProducts;
    });
  });

  it(@"should create products from the list of variants", ^{
    BZRProduct *firstProduct = BZRProductWithIdentifier(@"foo");
    firstProduct =
        [firstProduct modelByOverridingProperty:@keypath(firstProduct, discountedProducts)
                                      withValue:@[@"foo.25Off", @"foo.75Off"]];
    BZRProduct *secondProduct = BZRProductWithIdentifier(@"bar");
    secondProduct =
        [secondProduct modelByOverridingProperty:@keypath(secondProduct, discountedProducts)
                                       withValue:@[@"bar.25Off", @"bar.50Off"]];
    NSArray<BZRProduct *> *productList = @[firstProduct, secondProduct];
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal return:productList]);

    LLSignalTestRecorder *recorder = [[provider fetchProductList] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.matchValue(0, ^BOOL(NSArray<BZRProduct *> *productList) {
      NSSet<NSString *> *productsIdentifiers = [NSSet setWithArray:
          [productList valueForKey:@instanceKeypath(BZRProduct, identifier)]];
      return [productList count] == 6 &&
          [productsIdentifiers isEqualToSet:
           [NSSet setWithObjects:@"foo", @"foo.25Off", @"foo.75Off", @"bar", @"bar.25Off",
            @"bar.50Off", nil]];
    });
  });
});

SpecEnd
