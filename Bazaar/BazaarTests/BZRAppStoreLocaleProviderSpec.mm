// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRAppStoreLocaleProvider.h"

#import "BZRProduct+StoreKit.h"
#import "BZRProductsProvider.h"
#import "BZRStoreKitMetadataFetcher.h"
#import "BZRTestUtils.h"

SpecBegin(BZRAppStoreLocaleProvider)

__block id<BZRProductsProvider> productsProvider;
__block BZRStoreKitMetadataFetcher *storeKitMetadataFetcher;
__block BZRProduct *nonSubscriptionProduct;
__block BZRProduct *firstSubscriptionProduct;
__block BZRProduct *secondSubscriptionProduct;
__block BZRAppStoreLocaleProvider *localeProvider;

beforeEach(^{
  productsProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
  storeKitMetadataFetcher = OCMClassMock([BZRStoreKitMetadataFetcher class]);
  nonSubscriptionProduct = OCMClassMock([BZRProduct class]);

  SKProduct *firstStoreKitProduct =
      BZRSKProductWithProperties(@"foo", [NSDecimalNumber decimalNumberWithString:@"1"], @"en_US");
  firstSubscriptionProduct = OCMClassMock([BZRProduct class]);
  OCMStub([firstSubscriptionProduct isSubscriptionProduct]).andReturn(YES);
  OCMStub([firstSubscriptionProduct underlyingProduct]).andReturn(firstStoreKitProduct);

  SKProduct *secondStoreKitProduct =
      BZRSKProductWithProperties(@"boo", [NSDecimalNumber decimalNumberWithString:@"1"], @"en_GB");
  secondSubscriptionProduct = OCMClassMock([BZRProduct class]);
  OCMStub([secondSubscriptionProduct isSubscriptionProduct]).andReturn(YES);
  OCMStub([secondSubscriptionProduct underlyingProduct]).andReturn(secondStoreKitProduct);

  OCMStub([productsProvider fetchProductList]).andReturn(([RACSignal return:@[
    nonSubscriptionProduct,
    firstSubscriptionProduct,
    secondSubscriptionProduct
  ]]));
});

it(@"should not fetch non subscription products when fetching the locale", ^{
  OCMReject([storeKitMetadataFetcher fetchProductsMetadata:@[nonSubscriptionProduct]]);
  OCMExpect([storeKitMetadataFetcher fetchProductsMetadata:@[firstSubscriptionProduct]])
      .andReturn([RACSignal return:@[firstSubscriptionProduct]]);

  localeProvider = [[BZRAppStoreLocaleProvider alloc]
                    initWithProductsProvider:productsProvider
                    metadataFetcher:storeKitMetadataFetcher];

  OCMVerifyAll((id)storeKitMetadataFetcher);
});

it(@"should update the locale according to the first subscription product", ^{
  OCMStub([storeKitMetadataFetcher fetchProductsMetadata:@[firstSubscriptionProduct]])
      .andReturn([RACSignal return:@[firstSubscriptionProduct]]);

  localeProvider = [[BZRAppStoreLocaleProvider alloc]
                    initWithProductsProvider:productsProvider
                    metadataFetcher:storeKitMetadataFetcher];

  expect(localeProvider.appStoreLocale).to
      .equal([[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]);
});

it(@"should fetch only the first product if it was successful", ^{
  OCMExpect([storeKitMetadataFetcher fetchProductsMetadata:@[firstSubscriptionProduct]])
      .andReturn([RACSignal return:@[firstSubscriptionProduct]]);
  OCMReject([storeKitMetadataFetcher fetchProductsMetadata:@[secondSubscriptionProduct]]);

  localeProvider = [[BZRAppStoreLocaleProvider alloc]
                    initWithProductsProvider:productsProvider
                    metadataFetcher:storeKitMetadataFetcher];

  OCMVerifyAll((id)storeKitMetadataFetcher);
});

it(@"should fetch the second product if the first fetch fails", ^{
  OCMExpect([storeKitMetadataFetcher fetchProductsMetadata:@[firstSubscriptionProduct]])
      .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
  OCMExpect([storeKitMetadataFetcher fetchProductsMetadata:@[secondSubscriptionProduct]])
      .andReturn([RACSignal return:@[secondSubscriptionProduct]]);

  localeProvider = [[BZRAppStoreLocaleProvider alloc]
                    initWithProductsProvider:productsProvider
                    metadataFetcher:storeKitMetadataFetcher];

  expect(localeProvider.appStoreLocale).will
      .equal([[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]);
  OCMVerifyAll((id)storeKitMetadataFetcher);
});

it(@"should not change the App Store locale if none of the fetches completed successfully", ^{
  OCMStub([storeKitMetadataFetcher fetchProductsMetadata:@[firstSubscriptionProduct]])
      .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
  OCMStub([storeKitMetadataFetcher fetchProductsMetadata:@[secondSubscriptionProduct]])
      .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);

  localeProvider = [[BZRAppStoreLocaleProvider alloc]
                    initWithProductsProvider:productsProvider
                    metadataFetcher:storeKitMetadataFetcher];

  expect(localeProvider.appStoreLocale).to.beNil();
});

it(@"should dealloc successfully", ^{
  __weak BZRAppStoreLocaleProvider *weakLocaleProvider;

  @autoreleasepool {
    OCMStub([storeKitMetadataFetcher fetchProductsMetadata:@[firstSubscriptionProduct]])
        .andReturn([RACSignal return:@[firstSubscriptionProduct]]);
    OCMStub([storeKitMetadataFetcher fetchProductsMetadata:@[secondSubscriptionProduct]])
        .andReturn([RACSignal return:@[secondSubscriptionProduct]]);
    auto strongLocaleProvider = [[BZRAppStoreLocaleProvider alloc]
                                 initWithProductsProvider:productsProvider
                                 metadataFetcher:storeKitMetadataFetcher];
    weakLocaleProvider = strongLocaleProvider;
  }

  expect(weakLocaleProvider).to.beNil();
});

SpecEnd
