// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRAppStoreLocaleProvider.h"

#import "BZRAppStoreLocaleCache.h"
#import "BZRProduct+StoreKit.h"
#import "BZRProductsProvider.h"
#import "BZRStoreKitMetadataFetcher.h"
#import "BZRTestUtils.h"

SpecBegin(BZRAppStoreLocaleProvider)

__block id<BZRProductsProvider> productsProvider;
__block BZRStoreKitMetadataFetcher *storeKitMetadataFetcher;
__block BZRAppStoreLocaleCache *appStoreLocaleCache;
__block BZRProduct *nonSubscriptionProduct;
__block BZRProduct *firstSubscriptionProduct;
__block BZRProduct *secondSubscriptionProduct;
__block BZRAppStoreLocaleProvider *localeProvider;

beforeEach(^{
  productsProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
  storeKitMetadataFetcher = OCMClassMock([BZRStoreKitMetadataFetcher class]);
  appStoreLocaleCache = OCMClassMock([BZRAppStoreLocaleCache class]);
  nonSubscriptionProduct = OCMClassMock([BZRProduct class]);

  auto firstStoreKitProduct = BZRMockedSKProductWithProperties(
      @"foo", [NSDecimalNumber decimalNumberWithString:@"1"], @"en_US");
  firstSubscriptionProduct = OCMClassMock([BZRProduct class]);
  OCMStub([firstSubscriptionProduct isSubscriptionProduct]).andReturn(YES);
  OCMStub([firstSubscriptionProduct underlyingProduct]).andReturn(firstStoreKitProduct);

  auto secondStoreKitProduct = BZRMockedSKProductWithProperties(
      @"boo", [NSDecimalNumber decimalNumberWithString:@"1"], @"en_GB");
  secondSubscriptionProduct = OCMClassMock([BZRProduct class]);
  OCMStub([secondSubscriptionProduct isSubscriptionProduct]).andReturn(YES);
  OCMStub([secondSubscriptionProduct underlyingProduct]).andReturn(secondStoreKitProduct);

  OCMStub([productsProvider fetchProductList]).andReturn(([RACSignal return:@[
    nonSubscriptionProduct,
    firstSubscriptionProduct,
    secondSubscriptionProduct
  ]]));
});

it(@"should load the current application's App Store locale from cache on initialization", ^{
  auto appStoreLocale = [NSLocale currentLocale];
  OCMExpect([appStoreLocaleCache appStoreLocaleForBundleID:@"foo" error:nil])
      .andReturn(appStoreLocale);

  OCMStub([storeKitMetadataFetcher fetchProductsMetadata:OCMOCK_ANY]).andReturn([RACSignal never]);

  localeProvider = [[BZRAppStoreLocaleProvider alloc]
                    initWithCache:appStoreLocaleCache productsProvider:productsProvider
                    metadataFetcher:storeKitMetadataFetcher currentApplicationBundleID:@"foo"];

  expect(localeProvider.appStoreLocale).to.equal(appStoreLocale);
  OCMVerifyAll(appStoreLocaleCache);
});

it(@"should store the current application's App Store locale to cache after fetching", ^{
  auto expectedFetchedLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
  OCMExpect([appStoreLocaleCache storeAppStoreLocale:expectedFetchedLocale bundleID:@"foo"
                                               error:nil]);
  OCMStub([storeKitMetadataFetcher fetchProductsMetadata:@[firstSubscriptionProduct]])
      .andReturn([RACSignal return:@[firstSubscriptionProduct]]);

  localeProvider = [[BZRAppStoreLocaleProvider alloc]
                    initWithCache:appStoreLocaleCache productsProvider:productsProvider
                    metadataFetcher:storeKitMetadataFetcher currentApplicationBundleID:@"foo"];

  OCMVerifyAll(appStoreLocaleCache);
});

it(@"should not fetch non subscription products when fetching the locale", ^{
  OCMReject([storeKitMetadataFetcher fetchProductsMetadata:@[nonSubscriptionProduct]]);
  OCMExpect([storeKitMetadataFetcher fetchProductsMetadata:@[firstSubscriptionProduct]])
      .andReturn([RACSignal return:@[firstSubscriptionProduct]]);

  localeProvider = [[BZRAppStoreLocaleProvider alloc]
                    initWithCache:appStoreLocaleCache productsProvider:productsProvider
                    metadataFetcher:storeKitMetadataFetcher currentApplicationBundleID:@"foo"];

  OCMVerifyAll(storeKitMetadataFetcher);
});

it(@"should update the locale according to the first subscription product", ^{
  OCMStub([storeKitMetadataFetcher fetchProductsMetadata:@[firstSubscriptionProduct]])
      .andReturn([RACSignal return:@[firstSubscriptionProduct]]);

  localeProvider = [[BZRAppStoreLocaleProvider alloc]
                    initWithCache:appStoreLocaleCache productsProvider:productsProvider
                    metadataFetcher:storeKitMetadataFetcher currentApplicationBundleID:@"foo"];

  expect(localeProvider.appStoreLocale).to
      .equal([[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]);
});

it(@"should filter empty product list", ^{
  productsProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
  OCMStub([productsProvider fetchProductList])
      .andReturn(([RACSignal return:@[nonSubscriptionProduct]]));

  localeProvider = [[BZRAppStoreLocaleProvider alloc]
                    initWithCache:appStoreLocaleCache productsProvider:productsProvider
                    metadataFetcher:storeKitMetadataFetcher currentApplicationBundleID:@"foo"];

  expect(localeProvider.appStoreLocale).will.beNil();
});

it(@"should fetch only the first product if it was successful", ^{
  OCMExpect([storeKitMetadataFetcher fetchProductsMetadata:@[firstSubscriptionProduct]])
      .andReturn([RACSignal return:@[firstSubscriptionProduct]]);
  OCMReject([storeKitMetadataFetcher fetchProductsMetadata:@[secondSubscriptionProduct]]);

  localeProvider = [[BZRAppStoreLocaleProvider alloc]
                    initWithCache:appStoreLocaleCache productsProvider:productsProvider
                    metadataFetcher:storeKitMetadataFetcher currentApplicationBundleID:@"foo"];

  OCMVerifyAll(storeKitMetadataFetcher);
});

it(@"should fetch the second product if the first fetch fails", ^{
  OCMExpect([storeKitMetadataFetcher fetchProductsMetadata:@[firstSubscriptionProduct]])
      .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
  OCMExpect([storeKitMetadataFetcher fetchProductsMetadata:@[secondSubscriptionProduct]])
      .andReturn([RACSignal return:@[secondSubscriptionProduct]]);

  localeProvider = [[BZRAppStoreLocaleProvider alloc]
                    initWithCache:appStoreLocaleCache productsProvider:productsProvider
                    metadataFetcher:storeKitMetadataFetcher currentApplicationBundleID:@"foo"];

  expect(localeProvider.appStoreLocale).will
      .equal([[NSLocale alloc] initWithLocaleIdentifier:@"en_GB"]);
  OCMVerifyAll(storeKitMetadataFetcher);
});

it(@"should not change the App Store locale if none of the fetches completed successfully", ^{
  OCMStub([storeKitMetadataFetcher fetchProductsMetadata:@[firstSubscriptionProduct]])
      .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
  OCMStub([storeKitMetadataFetcher fetchProductsMetadata:@[secondSubscriptionProduct]])
      .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);

  localeProvider = [[BZRAppStoreLocaleProvider alloc]
                    initWithCache:appStoreLocaleCache productsProvider:productsProvider
                    metadataFetcher:storeKitMetadataFetcher currentApplicationBundleID:@"foo"];

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
                                 initWithCache:appStoreLocaleCache productsProvider:productsProvider
                                 metadataFetcher:storeKitMetadataFetcher
                                 currentApplicationBundleID:@"foo"];
    weakLocaleProvider = strongLocaleProvider;
  }

  expect(weakLocaleProvider).to.beNil();
});

context(@"storing and loading App Store locale from cache", ^{
  beforeEach(^{
    OCMStub([storeKitMetadataFetcher fetchProductsMetadata:OCMOCK_ANY])
        .andReturn([RACSignal never]);
    localeProvider = [[BZRAppStoreLocaleProvider alloc]
                      initWithCache:appStoreLocaleCache productsProvider:productsProvider
                      metadataFetcher:storeKitMetadataFetcher currentApplicationBundleID:@"foo"];
  });

  it(@"should store App Store locale to cache", ^{
    auto appStoreLocale = [NSLocale currentLocale];

    [localeProvider storeAppStoreLocale:appStoreLocale bundleID:@"foo" error:nil];

    OCMVerify([appStoreLocaleCache storeAppStoreLocale:appStoreLocale bundleID:@"foo" error:nil]);
  });

  it(@"should load App Store locale from cache", ^{
    [localeProvider appStoreLocaleForBundleID:@"foo" error:nil];

    OCMVerify([appStoreLocaleCache appStoreLocaleForBundleID:@"foo" error:nil]);
  });
});

SpecEnd
