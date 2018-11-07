// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRStoreKitCachedMetadataFetcher.h"

#import "BZRProduct+StoreKit.h"
#import "BZRProductPriceInfo.h"
#import "BZRStoreKitMetadataFetcher.h"
#import "BZRTestUtils.h"

SpecBegin(BZRStoreKitCachedMetadataFetcher)

__block BZRStoreKitMetadataFetcher *underlyingFetcher;
__block BZRStoreKitCachedMetadataFetcher *storeKitMetadataFetcher;
__block BZRProduct *product;
__block BZRProduct *productWithMetadata;

beforeEach(^{
  underlyingFetcher = OCMClassMock([BZRStoreKitMetadataFetcher class]);
  storeKitMetadataFetcher =
      [[BZRStoreKitCachedMetadataFetcher alloc] initWithUnderlyingFetcher:underlyingFetcher];
  product = BZRProductWithIdentifier(@"foo");
  auto storeKitProduct = BZRMockedSKProductWithProperties(@"foo");
  productWithMetadata = [product productByAssociatingStoreKitProduct:storeKitProduct];
});

it(@"should send cached products", ^{
  OCMExpect([underlyingFetcher fetchProductsMetadata:@[product]])
      .andReturn([RACSignal return:@[productWithMetadata]]);
  OCMExpect([underlyingFetcher fetchProductsMetadata:@[]]).andReturn([RACSignal return:@[]]);

  auto firstCallRecorder =
      [[storeKitMetadataFetcher fetchProductsMetadata:@[product]] testRecorder];
  auto secondCallRecorder =
      [[storeKitMetadataFetcher fetchProductsMetadata:@[product]] testRecorder];

  expect(firstCallRecorder).to.sendValues(@[@[productWithMetadata]]);
  expect(secondCallRecorder).to.sendValues(@[@[productWithMetadata]]);
  OCMVerifyAll(underlyingFetcher);
});

it(@"should refetch the products metadata after cache was cleared", ^{
  OCMExpect([underlyingFetcher fetchProductsMetadata:@[product]])
      .andReturn([RACSignal return:@[productWithMetadata]]);
  OCMExpect([underlyingFetcher fetchProductsMetadata:@[product]])
      .andReturn([RACSignal return:@[productWithMetadata]]);

  auto firstCallRecorder =
      [[storeKitMetadataFetcher fetchProductsMetadata:@[product]] testRecorder];
  [storeKitMetadataFetcher clearProductsMetadataCache];
  auto secondCallRecorder =
      [[storeKitMetadataFetcher fetchProductsMetadata:@[product]] testRecorder];

  expect(firstCallRecorder).to.sendValues(@[@[productWithMetadata]]);
  expect(secondCallRecorder).to.sendValues(@[@[productWithMetadata]]);
  OCMVerifyAll(underlyingFetcher);
});

it(@"should send error if the underlying fetcher sends error", ^{
  auto error = [NSError lt_errorWithCode:1337];
  OCMStub([underlyingFetcher fetchProductsMetadata:@[product]]).andReturn([RACSignal error:error]);

  auto recorder = [[storeKitMetadataFetcher fetchProductsMetadata:@[product]] testRecorder];

  expect(recorder).to.sendError(error);
});

it(@"should send cached product with the full price added to it", ^{
  product = [product
      modelByOverridingProperty:@keypath(product, fullPriceProductIdentifier) withValue:@"bar"];
  productWithMetadata = [productWithMetadata
      modelByOverridingProperty:@keypath(product, fullPriceProductIdentifier) withValue:@"bar"];

  auto fullPriceProduct = BZRProductWithIdentifier(@"bar");
  auto fullPriceSKProduct =
      BZRMockedSKProductWithProperties(@"bar", [NSDecimalNumber decimalNumberWithString:@"2"]);
  auto fullPriceProductWithMetadata =
      [fullPriceProduct productByAssociatingStoreKitProduct:fullPriceSKProduct];

  auto requestedProducts = @[product, fullPriceProduct];
  OCMExpect([underlyingFetcher fetchProductsMetadata:requestedProducts])
      .andReturn(([RACSignal return:@[productWithMetadata, fullPriceProductWithMetadata]]));
  OCMExpect([underlyingFetcher fetchProductsMetadata:@[]]).andReturn([RACSignal return:@[]]);

  [[storeKitMetadataFetcher fetchProductsMetadata:requestedProducts] testRecorder];
  auto secondCallRecorder =
      [[storeKitMetadataFetcher fetchProductsMetadata:requestedProducts] testRecorder];

  auto productWithFullPrice = [productWithMetadata
      modelByOverridingPropertyAtKeypath:@keypath(productWithMetadata, priceInfo.fullPrice)
      withValue:fullPriceProductWithMetadata.priceInfo.price];
  auto expectedProducts = @[productWithFullPrice, fullPriceProductWithMetadata];
  expect(secondCallRecorder).to.sendValues(@[expectedProducts]);
  OCMVerifyAll(underlyingFetcher);
});

context(@"deallocating object", ^{
  beforeEach(^{
    OCMStub([underlyingFetcher fetchProductsMetadata:@[product]])
        .andReturn([RACSignal return:@[productWithMetadata]]);
  });

  it(@"should deallocate successfully after fetch", ^{
    __weak BZRStoreKitCachedMetadataFetcher *weakFetcher;
    LLSignalTestRecorder *recorder;

    @autoreleasepool {
      BZRStoreKitCachedMetadataFetcher *fetcher =
          [[BZRStoreKitCachedMetadataFetcher alloc] initWithUnderlyingFetcher:underlyingFetcher];
      weakFetcher = fetcher;

      recorder = [[weakFetcher fetchProductsMetadata:@[product]] testRecorder];
    }

    expect(weakFetcher).to.beNil();
  });
});

SpecEnd
