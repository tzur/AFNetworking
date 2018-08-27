// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreKitMetadataFetcher.h"

#import <LTKit/NSArray+Functional.h>

#import "BZREvent.h"
#import "BZRProduct+StoreKit.h"
#import "BZRProductPriceInfo.h"
#import "BZRStoreKitFacade.h"
#import "BZRTestUtils.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRStoreKitMetadataFetcher)

__block BZRStoreKitFacade *storeKitFacade;
__block BZRStoreKitMetadataFetcher *storeKitMetadataFetcher;
__block BZRProduct *product;

beforeEach(^{
  storeKitFacade = OCMClassMock([BZRStoreKitFacade class]);
  storeKitMetadataFetcher =
      [[BZRStoreKitMetadataFetcher alloc] initWithStoreKitFacade:storeKitFacade];
  product = BZRProductWithIdentifier(@"foo");
});

context(@"getting product list", ^{
  it(@"should dealloc when all strong references are relinquished", ^{
    BZRStoreKitMetadataFetcher * __weak weakstoreKitMetadataFetcher;
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal error:error]);

    RACSignal *priceInfoSignal;
    @autoreleasepool {
      auto storeKitMetadataFetcher =
          [[BZRStoreKitMetadataFetcher alloc] initWithStoreKitFacade:storeKitFacade];
      weakstoreKitMetadataFetcher = storeKitMetadataFetcher;

      priceInfoSignal = [storeKitMetadataFetcher fetchProductsMetadata:@[product]];
    }

    expect(priceInfoSignal).will.finish();
    expect(weakstoreKitMetadataFetcher).to.beNil();
  });

  it(@"should send error when store kit facade errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal error:error]);

    expect([storeKitMetadataFetcher fetchProductsMetadata:@[product]]).will.sendError(error);
  });

  it(@"should send error when product list doesn't contain any product", ^{
    SKProductsResponse *response = OCMClassMock([SKProductsResponse class]);
    OCMStub([response products]).andReturn(@[]);
    OCMStub([response invalidProductIdentifiers]).andReturn(@[product.identifier]);
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal return:response]);

    NSError *error = [NSError bzr_invalidProductsErrorWithIdentifiers:@[product.identifier].lt_set];
    expect([storeKitMetadataFetcher fetchProductsMetadata:@[product]]).will.sendError(error);
  });

  it(@"should send error event if product list contains some invalid product identifiers", ^{
    SKProductsResponse *response = OCMClassMock([SKProductsResponse class]);
    OCMStub([response products]).andReturn(@[]);
    OCMStub([response invalidProductIdentifiers]).andReturn(@[product.identifier]);
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal return:response]);

    auto recorder = [storeKitMetadataFetcher.eventsSignal testRecorder];

    expect([storeKitMetadataFetcher fetchProductsMetadata:@[product]]).will.finish();
    expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      NSError *error = event.eventError;
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] && error.lt_isLTDomain &&
          error.code == BZRErrorCodeInvalidProductIdentifier &&
          [error.bzr_productIdentifiers isEqual:[NSSet setWithObject:product.identifier]];
    });
  });

  it(@"should return set containing the requested product if fetching that product's metadata "
     "succeeded", ^{
    auto response = BZRMockedProductsResponseWithProduct(@"foo");
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal return:response]);

    auto recorder = [[storeKitMetadataFetcher fetchProductsMetadata:@[product]] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.matchValue(0, ^BOOL(NSArray<BZRProduct *> *productList) {
      return [productList count] == 1 &&
          [productList.firstObject.identifier isEqualToString:@"foo"];
    });
  });

  it(@"should return empty list if facade returns a response with another product", ^{
    auto response = BZRMockedProductsResponseWithProduct(@"bar");
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal return:response]);

    auto recorder = [[storeKitMetadataFetcher fetchProductsMetadata:@[product]] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@[]]);
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
      fullPriceUnderlyingProduct = BZRMockedSKProductWithProperties(@"foo", fullPrice);

      discountedPrice = [NSDecimalNumber decimalNumberWithString:@"13"];
      discountedProduct = BZRProductWithIdentifier(@"bar");
      discountedProduct = [discountedProduct
          modelByOverridingProperty:@keypath(discountedProduct, fullPriceProductIdentifier)
          withValue:fullPriceProduct.identifier];
      discountedUnderlyingProduct = BZRMockedSKProductWithProperties(@"bar", discountedPrice);

      productList = @[fullPriceProduct, discountedProduct];
      productsResponse = BZRMockedProductsResponseWithSKProducts(@[
        fullPriceUnderlyingProduct,
        discountedUnderlyingProduct
      ]);
      OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
          .andReturn([RACSignal return:productsResponse]);
    });

    it(@"should set full price correctly", ^{
      auto recorder = [[storeKitMetadataFetcher fetchProductsMetadata:productList] testRecorder];

      expect(recorder).will.matchValue(0, ^BOOL(NSSet<BZRProduct *> *productList) {
        return [[productList.allObjects lt_filter:^BOOL(BZRProduct *product) {
          return [product.identifier isEqualToString:@"bar"];
        }].firstObject.priceInfo.fullPrice isEqualToNumber:fullPrice];
      });
    });
  });
});

SpecEnd
