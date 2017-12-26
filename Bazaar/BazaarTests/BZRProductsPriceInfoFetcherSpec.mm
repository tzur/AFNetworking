// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsPriceInfoFetcher.h"

#import <LTKit/NSArray+Functional.h>

#import "BZREvent.h"
#import "BZRProduct+SKProduct.h"
#import "BZRProductPriceInfo+SKProduct.h"
#import "BZRStoreKitFacade.h"
#import "BZRTestUtils.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

SKProduct *BZRProductWithProperties(NSString *productIdentifier, NSDecimalNumber *price,
                                    NSLocale *locale) {
  SKProduct *product = OCMClassMock([SKProduct class]);
  OCMStub([product price]).andReturn(price);
  OCMStub([product priceLocale]).andReturn(locale);
  OCMStub([product productIdentifier]).andReturn(productIdentifier);
  return product;
}

SpecBegin(BZRProductsPriceInfoFetcher)

__block BZRStoreKitFacade *storeKitFacade;
__block BZRProductsPriceInfoFetcher *priceInfoFetcher;
__block BZRProduct *product;

beforeEach(^{
  storeKitFacade = OCMClassMock([BZRStoreKitFacade class]);
  priceInfoFetcher = [[BZRProductsPriceInfoFetcher alloc] initWithStoreKitFacade:storeKitFacade];
  product = BZRProductWithIdentifier(@"foo");
});

context(@"getting product list", ^{
  it(@"should dealloc when all strong references are relinquished", ^{
    BZRProductsPriceInfoFetcher * __weak weakPriceInfoFetcher;
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal error:error]);

    RACSignal *priceInfoSignal;
    @autoreleasepool {
      auto priceInfoFetcher =
          [[BZRProductsPriceInfoFetcher alloc] initWithStoreKitFacade:storeKitFacade];
      weakPriceInfoFetcher = priceInfoFetcher;

      priceInfoSignal = [priceInfoFetcher fetchProductsPriceInfo:@[product]];
    }

    expect(priceInfoSignal).will.finish();
    expect(weakPriceInfoFetcher).to.beNil();
  });

  it(@"should send error when failed to fetch products metadata", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal error:error]);

    expect([priceInfoFetcher fetchProductsPriceInfo:@[product]]).will.sendError(error);
  });

  it(@"should send error event if product list contains some invalid product identifiers", ^{
    SKProductsResponse *response = OCMClassMock([SKProductsResponse class]);
    OCMStub([response products]).andReturn(@[]);
    OCMStub([response invalidProductIdentifiers]).andReturn(@[product.identifier]);
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal return:response]);

    auto recorder = [priceInfoFetcher.eventsSignal testRecorder];

    [[priceInfoFetcher fetchProductsPriceInfo:@[product]] subscribeNext:^(id) {}];

    expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      NSError *error = event.eventError;
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] && error.lt_isLTDomain &&
          error.code == BZRErrorCodeInvalidProductIdentifier &&
          [error.bzr_productIdentifiers isEqual:[NSSet setWithObject:product.identifier]];
    });
  });

  it(@"should return set with product if facade returns a response with the same product", ^{
    SKProductsResponse *response = BZRProductsResponseWithProduct(@"foo");
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal return:response]);

    auto recorder = [[priceInfoFetcher fetchProductsPriceInfo:@[product]] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.matchValue(0, ^BOOL(NSArray<BZRProduct *> *productList) {
      return [productList count] == 1 &&
          [productList.firstObject.identifier isEqualToString:@"foo"];
    });
  });

  it(@"should return empty list if facade returns a response with another product", ^{
    SKProductsResponse *response = BZRProductsResponseWithProduct(@"bar");
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal return:response]);

    auto recorder = [[priceInfoFetcher fetchProductsPriceInfo:@[product]] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@[]]);
  });

  it(@"should set price info correctly", ^{
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
    NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithString:@"1337.1337"];
    auto underlyingProduct = BZRProductWithProperties(@"foo", price, locale);
    SKProductsResponse *response = BZRProductsResponseWithSKProducts(@[underlyingProduct]);
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal return:response]);

    auto recorder = [[priceInfoFetcher fetchProductsPriceInfo:@[product]] testRecorder];

    expect(recorder).will.matchValue(0, ^BOOL(NSSet<BZRProduct *> *productList) {
      BZRProductPriceInfo *priceInfo = [productList allObjects].firstObject.priceInfo;
      return [priceInfo.localeIdentifier isEqualToString:@"de_DE"] &&
          [priceInfo.price isEqualToNumber:price];
    });
  });

  context(@"setting full price for discount product", ^{
    __block BZRProduct *fullPriceProduct;
    __block SKProduct *fullPriceUnderlyingProduct;
    __block NSDecimalNumber *fullPrice;
    __block BZRProduct *discountedProduct;
    __block SKProduct *discountedUnderlyingProduct;
    __block NSDecimalNumber *discountedPrice;
    __block SKProductsResponse *productsResponse;
    __block NSArray<BZRProduct *> *productList;

    beforeEach(^{
      fullPriceProduct = BZRProductWithIdentifier(@"foo");
      fullPriceProduct = [fullPriceProduct
          modelByOverridingProperty:@keypath(fullPriceProduct, discountedProducts)
          withValue:@[@"bar"]];
      fullPrice = [NSDecimalNumber decimalNumberWithString:@"1337.1337"];
      fullPriceUnderlyingProduct =
          BZRProductWithProperties(@"foo", fullPrice, [NSLocale currentLocale]);

      discountedPrice = [NSDecimalNumber decimalNumberWithString:@"13"];
      discountedProduct = BZRProductWithIdentifier(@"bar");
      discountedProduct = [discountedProduct
          modelByOverridingProperty:@keypath(discountedProduct, fullPriceProductIdentifier)
          withValue:fullPriceProduct.identifier];
      discountedUnderlyingProduct =
          BZRProductWithProperties(@"bar", discountedPrice, [NSLocale currentLocale]);

      productList = @[fullPriceProduct, discountedProduct];
      productsResponse = BZRProductsResponseWithSKProducts(@[
        fullPriceUnderlyingProduct,
        discountedUnderlyingProduct
      ]);
      OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
          .andReturn([RACSignal return:productsResponse]);
    });

    it(@"should set full price correctly", ^{
      auto recorder = [[priceInfoFetcher fetchProductsPriceInfo:productList] testRecorder];

      expect(recorder).will.matchValue(0, ^BOOL(NSSet<BZRProduct *> *productList) {
        return [[productList.allObjects lt_filter:^BOOL(BZRProduct *product) {
          return [product.identifier isEqualToString:@"bar"];
        }].firstObject.priceInfo.fullPrice isEqualToNumber:fullPrice];
      });
    });

    it(@"should set underlying product correctly", ^{
      auto recorder = [[priceInfoFetcher fetchProductsPriceInfo:productList] testRecorder];

      expect(recorder).will.matchValue(0, ^BOOL(NSSet<BZRProduct *> *productList) {
        return [productList.allObjects lt_filter:^BOOL(BZRProduct *product) {
          return [product.identifier isEqualToString:@"bar"];
        }].firstObject.bzr_underlyingProduct == discountedUnderlyingProduct;
      });
    });
  });
});

SpecEnd
