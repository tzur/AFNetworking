// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsWithPriceInfoProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZREvent.h"
#import "BZRProduct.h"
#import "BZRProductPriceInfo+SKProduct.h"
#import "BZRProductsPriceInfoFetcher.h"
#import "BZRStoreKitFacade.h"
#import "BZRTestUtils.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRProductsWithPriceInfoProvider)

__block id<BZRProductsProvider> underlyingProvider;
__block RACSubject *underlyingProviderEventsSubject;
__block BZRProductsPriceInfoFetcher *priceInfoFetcher;
__block BZRProductsWithPriceInfoProvider *productsProvider;

beforeEach(^{
  underlyingProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
  underlyingProviderEventsSubject = [RACSubject subject];
  OCMStub([underlyingProvider eventsSignal]).andReturn(underlyingProviderEventsSubject);
  priceInfoFetcher = OCMClassMock([BZRProductsPriceInfoFetcher class]);
  productsProvider =
      [[BZRProductsWithPriceInfoProvider alloc] initWithUnderlyingProvider:underlyingProvider
                                                          priceInfoFetcher:priceInfoFetcher];
});

context(@"getting product list", ^{
  __block BZRProduct *product;

  beforeEach(^{
    product = BZRProductWithIdentifier(@"foo");
  });

  it(@"should send error when underlying provider errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal error:error]);

    expect([productsProvider fetchProductList]).will.sendError(error);
  });

  it(@"should send non critical error when underlying provider sends non critical error", ^{
    LLSignalTestRecorder *recorder = [productsProvider.eventsSignal testRecorder];

    NSError *error = [NSError lt_errorWithCode:1337];
    [underlyingProviderEventsSubject sendNext:error];

    expect(recorder).to.sendValues(@[error]);
  });

  it(@"should send error when the returned product list is empty", ^{
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal return:@[product]]);
    OCMStub([priceInfoFetcher fetchProductsPriceInfo:OCMOCK_ANY]).andReturn([RACSignal return:@[]]);

    NSError *error = [NSError lt_errorWithCode:BZRErrorCodeProductsMetadataFetchingFailed];
    expect([productsProvider fetchProductList]).will.sendError(error);
  });

  it(@"should dealloc when all strong references are relinquished", ^{
    BZRProductsWithPriceInfoProvider * __weak weakProvider;
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMExpect([underlyingProvider fetchProductList]).andReturn([RACSignal error:error]);

    RACSignal *productListSignal;
    @autoreleasepool {
      BZRProductsWithPriceInfoProvider *provider =
          [[BZRProductsWithPriceInfoProvider alloc] initWithUnderlyingProvider:underlyingProvider
                                                                priceInfoFetcher:priceInfoFetcher];
      weakProvider = provider;
      expect([provider fetchProductList]).will.sendError(error);

      OCMExpect([underlyingProvider fetchProductList]).andReturn([RACSignal return:@[product]]);
      OCMStub([priceInfoFetcher fetchProductsPriceInfo:OCMOCK_ANY])
          .andReturn([RACSignal return:@[product]]);

      productListSignal = [provider fetchProductList];
    }
    expect(productListSignal).will.complete();
    expect(weakProvider).to.beNil();
  });

  it(@"should send error when failed to fetch products metadata", ^{
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal return:@[product]]);
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([priceInfoFetcher fetchProductsPriceInfo:OCMOCK_ANY])
        .andReturn([RACSignal error:error]);

    expect([productsProvider fetchProductList]).will.sendError(error);
  });

  context(@"subscribers only products", ^{
    __block BZRProduct *subscribersOnlyProduct;

    beforeEach(^{
      subscribersOnlyProduct =
          [BZRProductWithIdentifier(@"foo")
           modelByOverridingProperty:@instanceKeypath(BZRProduct, isSubscribersOnly)
                           withValue:@YES];
    });

    it(@"should not fetch metadata for subscribers only products", ^{
      OCMStub([underlyingProvider fetchProductList])
          .andReturn([RACSignal return:@[subscribersOnlyProduct]]);

      expect([productsProvider fetchProductList]).will.complete();

      OCMVerify([priceInfoFetcher fetchProductsPriceInfo:
                 [OCMArg checkWithBlock:^BOOL(BZRProductList *productList) {
                   return ![productList containsObject:subscribersOnlyProduct];
      }]]);
    });

    it(@"should merge subscribers only products with products with price info", ^{
      BZRProduct *nonSubscribersOnlyProduct = BZRProductWithIdentifier(@"bar");
      RACSignal *productList =
          [RACSignal return:@[subscribersOnlyProduct, nonSubscribersOnlyProduct]];
      OCMStub([underlyingProvider fetchProductList]).andReturn(productList);

      auto nonSubscribersOnlyProductWithPriceInfo =
          [nonSubscribersOnlyProduct
           modelByOverridingProperty:@keypath(nonSubscribersOnlyProduct, priceInfo)
           withValue:OCMClassMock([BZRProductPriceInfo class])];
      OCMExpect([priceInfoFetcher fetchProductsPriceInfo:@[nonSubscribersOnlyProduct]])
          .andReturn([RACSignal return:@[nonSubscribersOnlyProductWithPriceInfo]]);

      LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.matchValue(0, ^BOOL(NSArray<BZRProduct *> *productList) {
        BZRProduct *priceInfoProduct =
            [productList lt_find:^BOOL(BZRProduct *product) {
              return !product.isSubscribersOnly;
            }];
        BZRProduct *sentSubscribersOnlyProduct =
            [productList lt_find:^BOOL(BZRProduct *product) {
              return product.isSubscribersOnly;
            }];

        return [productList count] == 2 &&
            [priceInfoProduct isEqual:nonSubscribersOnlyProductWithPriceInfo] &&
            [sentSubscribersOnlyProduct isEqual:subscribersOnlyProduct];
      });
      OCMVerifyAll((id)priceInfoFetcher);
    });
  });

  context(@"products provider sends one product", ^{
    beforeEach(^{
      OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal return:@[product]]);
    });

    it(@"should send error if price info fetcher sends an error", ^{
      auto error = [NSError lt_errorWithCode:1337];
      OCMStub([priceInfoFetcher fetchProductsPriceInfo:OCMOCK_ANY])
          .andReturn([RACSignal error:error]);

      LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];

      expect(recorder).will.sendError(error);
    });

    it(@"should return the products returned by the price info fetcher", ^{
      OCMStub([priceInfoFetcher fetchProductsPriceInfo:OCMOCK_ANY])
          .andReturn([RACSignal return:@[product]]);

      LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.matchValue(0, ^BOOL(NSArray<BZRProduct *> *productList) {
        return [productList count] == 1 &&
            [productList.firstObject.identifier isEqualToString:@"foo"];
      });
    });

    it(@"should not include variants if their base product's metadata doesn't appear in products "
       "returned by price info fetcher", ^{
      BZRProduct *productVariant = BZRProductWithIdentifier(@"foo.Variant.A");

      OCMStub([priceInfoFetcher fetchProductsPriceInfo:OCMOCK_ANY])
          .andReturn([RACSignal return:@[productVariant]]);

      LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.matchValue(0, ^BOOL(NSArray<BZRProduct *> *productList) {
        return [productList count] == 0;
      });
    });
  });
});

SpecEnd
