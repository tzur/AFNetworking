// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductsWithPriceInfoProvider.h"

#import <LTKit/NSArray+Functional.h>

#import "BZREvent.h"
#import "BZRProduct+SKProduct.h"
#import "BZRProductPriceInfo+SKProduct.h"
#import "BZRStoreKitFacade.h"
#import "BZRTestUtils.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

SKProductsResponse *BZRProductsResponseWithProductWithProperties(NSString *productIdentifier,
    NSDecimalNumber *price, NSLocale *locale) {
  SKProduct *product = OCMClassMock([SKProduct class]);
  OCMStub([product price]).andReturn(price);
  OCMStub([product priceLocale]).andReturn(locale);
  OCMStub([product productIdentifier]).andReturn(productIdentifier);
  return BZRProductsResponseWithSKProducts(@[product]);
}

SpecBegin(BZRProductsWithPriceInfoProvider)

__block id<BZRProductsProvider> underlyingProvider;
__block RACSubject *underlyingProviderEventsSubject;
__block BZRStoreKitFacade *storeKitFacade;
__block BZRProductsWithPriceInfoProvider *productsProvider;

beforeEach(^{
  underlyingProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
  underlyingProviderEventsSubject = [RACSubject subject];
  OCMStub([underlyingProvider eventsSignal]).andReturn(underlyingProviderEventsSubject);
  storeKitFacade = OCMClassMock([BZRStoreKitFacade class]);
  productsProvider =
      [[BZRProductsWithPriceInfoProvider alloc] initWithUnderlyingProvider:underlyingProvider
                                                            storeKitFacade:storeKitFacade];
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

  it(@"should dealloc when all strong references are relinquished", ^{
    BZRProductsWithPriceInfoProvider * __weak weakProvider;
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMExpect([underlyingProvider fetchProductList]).andReturn([RACSignal error:error]);

    RACSignal *productListSignal;
    @autoreleasepool {
      BZRProductsWithPriceInfoProvider *provider =
          [[BZRProductsWithPriceInfoProvider alloc] initWithUnderlyingProvider:underlyingProvider
                                                                storeKitFacade:storeKitFacade];
      weakProvider = provider;
      expect([provider fetchProductList]).will.sendError(error);

      OCMExpect([underlyingProvider fetchProductList]).andReturn([RACSignal return:@[product]]);
      SKProductsResponse *response = BZRProductsResponseWithProduct(@"foo");
      OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
          .andReturn([RACSignal return:response]);

      productListSignal = [provider fetchProductList];
    }
    expect(productListSignal).will.complete();
    expect(weakProvider).to.beNil();
  });

  it(@"should send error when failed to fetch products metadata", ^{
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal return:@[product]]);
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal error:error]);

    expect([productsProvider fetchProductList]).will.sendError(error);
  });

  it(@"should send error if product list contains some invalid product identifers", ^{
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal return:@[product]]);

    SKProductsResponse *response = OCMClassMock([SKProductsResponse class]);
    OCMStub([response products]).andReturn(@[]);
    OCMStub([response invalidProductIdentifiers]).andReturn(@[product.identifier]);
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal return:response]);

    LLSignalTestRecorder *recorder = [productsProvider.eventsSignal testRecorder];

    [[productsProvider fetchProductList] subscribeNext:^(id) {}];

    expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      NSError *error = event.eventError;
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] && error.lt_isLTDomain &&
          error.code == BZRErrorCodeInvalidProductIdentifer &&
          [error.bzr_productIdentifiers isEqual:[NSSet setWithObject:product.identifier]];
    });
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
      OCMReject([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY]);

      expect([productsProvider fetchProductList]).will.complete();
    });

    it(@"should merge subscribers only products with products with price info", ^{
      BZRProduct *notForSubscribersOnlyProduct = BZRProductWithIdentifier(@"bar");
      RACSignal *productList =
          [RACSignal return:@[subscribersOnlyProduct, notForSubscribersOnlyProduct]];
      OCMStub([underlyingProvider fetchProductList]).andReturn(productList);

      SKProductsResponse *response = BZRProductsResponseWithProduct(@"bar");
      OCMExpect([storeKitFacade fetchMetadataForProductsWithIdentifiers:
                 [NSSet setWithObject:@"bar"]]).andReturn([RACSignal return:response]);

      LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.matchValue(0, ^BOOL(NSArray<BZRProduct *> *productList) {
        BZRProduct *priceInfoProduct =
            [productList lt_filter:^BOOL(BZRProduct *product) {
              return !product.isSubscribersOnly;
            }].firstObject;
        BZRProduct *subscribersOnlyProduct =
            [productList lt_filter:^BOOL(BZRProduct *product) {
              return product.isSubscribersOnly;
            }].firstObject;

        return [productList count] == 2 && [priceInfoProduct.identifier isEqualToString:@"bar"] &&
            priceInfoProduct.priceInfo &&
            [subscribersOnlyProduct.identifier isEqualToString:@"foo"] &&
            !subscribersOnlyProduct.priceInfo;
      });
      OCMVerifyAll((id)storeKitFacade);
    });
  });

  context(@"products provider sends one product", ^{
    beforeEach(^{
      OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal return:@[product]]);
    });

    it(@"should send error if facade returns a response without products", ^{
      SKProductsResponse *response = OCMClassMock([SKProductsResponse class]);
      OCMStub([response products]).andReturn(@[]);
      OCMStub([response invalidProductIdentifiers]).andReturn(@[@"foo"]);
      OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
          .andReturn([RACSignal return:response]);

      LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];

      NSError *error =
          [NSError bzr_invalidProductsErrorWithIdentifers:[NSSet setWithObject:@"foo"]];
      expect(recorder).will.sendError(error);
    });

    it(@"should return set with product if facade returns a response with the same product", ^{
      SKProductsResponse *response = BZRProductsResponseWithProduct(@"foo");
      OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
          .andReturn([RACSignal return:response]);

      LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];

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

      LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[@[]]);
    });

    it(@"should set price info correctly", ^{
      NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
      NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithString:@"1337.1337"];
      SKProductsResponse *response =
          BZRProductsResponseWithProductWithProperties(@"foo", price, locale);
      OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
          .andReturn([RACSignal return:response]);

      LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];

      expect(recorder).will.matchValue(0, ^BOOL(NSSet<BZRProduct *> *productList) {
        BZRProductPriceInfo *priceInfo = [productList allObjects].firstObject.priceInfo;
        return [priceInfo.localeIdentifier isEqualToString:@"de_DE"] &&
            [priceInfo.price isEqualToNumber:price];
      });
    });
  });

  it(@"should not include variants if thier base product's metadata can't be fetched", ^{
    SKProductsResponse *response = BZRProductsResponseWithProducts(@[@"foo.Variant.bar"]);
    OCMStub([response invalidProductIdentifiers]).andReturn(@[@"foo"]);
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal return:response]);

    product = [product modelByOverridingProperty:@keypath(product, variants)
                                       withValue:@[@"foo.Variant.bar"]];
    NSArray<BZRProduct *> *products = @[product, BZRProductWithIdentifier(@"foo.Variant.bar")];
    OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal return:products]);

    LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];

    expect(recorder).will.matchValue(0, ^BOOL(NSSet<BZRProduct *> *productList) {
      return [productList count] == 0;
    });
  });

  context(@"setting full price for discount product", ^{
    __block BZRProduct *fullPriceProduct;
    __block SKProduct *fullPriceUnderlyingProduct;
    __block NSDecimalNumber *fullPrice;
    __block BZRProduct *discountedProduct;
    __block SKProduct *discountedUnderlyingProduct;
    __block NSNumber *discountedPrice;
    __block SKProductsResponse *productsResponse;
    __block NSArray<BZRProduct *> *productList;

    beforeEach(^{
      fullPriceProduct = BZRProductWithIdentifier(@"foo");
      fullPriceProduct = [fullPriceProduct
          modelByOverridingProperty:@keypath(fullPriceProduct, discountedProducts)
          withValue:@[@"bar"]];
      fullPrice = [NSDecimalNumber decimalNumberWithString:@"1337.1337"];
      fullPriceUnderlyingProduct = OCMClassMock([SKProduct class]);
      OCMStub([fullPriceUnderlyingProduct productIdentifier]).andReturn(@"foo");
      OCMStub([fullPriceUnderlyingProduct price]).andReturn(fullPrice);
      OCMStub([fullPriceUnderlyingProduct priceLocale]).andReturn([NSLocale currentLocale]);

      discountedPrice = [NSDecimalNumber decimalNumberWithString:@"13"];
      discountedProduct = BZRProductWithIdentifier(@"bar");
      discountedProduct = [discountedProduct
          modelByOverridingProperty:@keypath(discountedProduct, fullPriceProductIdentifier)
          withValue:fullPriceProduct.identifier];
      discountedUnderlyingProduct = OCMClassMock([SKProduct class]);
      OCMStub([discountedUnderlyingProduct productIdentifier]).andReturn(@"bar");
      OCMStub([discountedUnderlyingProduct price]).andReturn(discountedPrice);
      OCMStub([discountedUnderlyingProduct priceLocale]).andReturn([NSLocale currentLocale]);

      productList = @[fullPriceProduct, discountedProduct];
      OCMStub([underlyingProvider fetchProductList]).andReturn([RACSignal return:productList]);

      productsResponse = BZRProductsResponseWithSKProducts(@[
        fullPriceUnderlyingProduct,
        discountedUnderlyingProduct
      ]);
      OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
          .andReturn([RACSignal return:productsResponse]);
    });

    it(@"should set full price correctly", ^{
      LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];

      expect(recorder).will.matchValue(0, ^BOOL(NSSet<BZRProduct *> *productList) {
        return [[productList.allObjects lt_filter:^BOOL(BZRProduct *product) {
          return [product.identifier isEqualToString:@"bar"];
        }].firstObject.priceInfo.fullPrice isEqualToNumber:fullPrice];
      });
    });

    it(@"should set underlying product correctly", ^{
      LLSignalTestRecorder *recorder = [[productsProvider fetchProductList] testRecorder];

      expect(recorder).will.matchValue(0, ^BOOL(NSSet<BZRProduct *> *productList) {
        return [productList.allObjects lt_filter:^BOOL(BZRProduct *product) {
          return [product.identifier isEqualToString:@"bar"];
        }].firstObject.bzr_underlyingProduct == discountedUnderlyingProduct;
      });
    });
  });
});

SpecEnd
