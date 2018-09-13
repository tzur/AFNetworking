// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import <OHHTTPStubs/OHHTTPStubs.h>
#import <UICKeyChainStore/UICKeyChainStore.h>

#import "BZRAllowedProductsProvider.h"
#import "BZRIntegrationTestUtils.h"
#import "BZRModel.h"
#import "BZRProduct.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationError.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRStore.h"
#import "BZRStoreConfiguration.h"
#import "BZRTestUtils.h"
#import "BZRTimeProvider.h"

SpecBegin(BZRStoreAllowedProductsIntegration)

__block UICKeyChainStore *keychainStore;
__block NSFileManager *fileManager;
__block SKPaymentQueue *paymentQueue;
__block BZRTimeProvider *timeProvider;
__block NSData *dataMock;
__block LTPath *JSONFilePath;

__block BZRProduct *purchasedProduct;
__block BZRProduct *notPurchasedProduct;
__block BZRProduct *enabledByPartialSubscriptionProduct;
__block BZRProduct *enabledByFullSubscriptionProduct;
__block BZRProduct *partialSubscriptionProduct;
__block BZRProduct *fullSubscriptionProduct;

__block BZRStore *store;

beforeEach(^{
  keychainStore = OCMClassMock([UICKeyChainStore class]);
  OCMStub([(id)keychainStore keyChainStoreWithService:OCMOCK_ANY accessGroup:OCMOCK_ANY])
      .andReturn(keychainStore);

  fileManager = OCMPartialMock([NSFileManager defaultManager]);

  paymentQueue = OCMClassMock([SKPaymentQueue class]);
  OCMStub([(id)paymentQueue defaultQueue]).andReturn(paymentQueue);

  timeProvider = OCMClassMock([BZRTimeProvider class]);
  OCMStub([(id)timeProvider defaultTimeProvider]).andReturn(timeProvider);
  OCMStub([timeProvider currentTime]).andReturn([RACSignal return:[NSDate date]]);

  dataMock = OCMClassMock([NSData class]);
  BZRStubDataMockReceiptData(dataMock, @"foofile");

  JSONFilePath = [LTPath pathWithPath:@"foopath"];

  purchasedProduct = BZRProductWithIdentifier(@"purchased");
  notPurchasedProduct = BZRProductWithIdentifier(@"not purchased");
  enabledByPartialSubscriptionProduct =
      BZRProductWithIdentifier(@"enabled by partial subscription");
  enabledByFullSubscriptionProduct = BZRProductWithIdentifier(@"enabled by full subscription");

  partialSubscriptionProduct = [[BZRProductWithIdentifier(@"partial subscription product")
    modelByOverridingProperty:@instanceKeypath(BZRProduct, productType)
                    withValue:$(BZRProductTypeNonRenewingSubscription)]
    modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts)
                    withValue:@[enabledByPartialSubscriptionProduct.identifier]];

  fullSubscriptionProduct = [BZRProductWithIdentifier(@"full subscription product")
    modelByOverridingProperty:@instanceKeypath(BZRProduct, productType)
                    withValue:$(BZRProductTypeNonRenewingSubscription)];

  BZRStubFileManagerToReturnJSONWithProducts(fileManager, JSONFilePath.path, @[
    purchasedProduct,
    notPurchasedProduct,
    enabledByPartialSubscriptionProduct,
    enabledByFullSubscriptionProduct,
    partialSubscriptionProduct,
    fullSubscriptionProduct
  ]);

  auto productsAcquiredViaSubscriptionSet = [NSKeyedArchiver archivedDataWithRootObject:@[
    purchasedProduct.identifier,
    notPurchasedProduct.identifier,
    enabledByPartialSubscriptionProduct.identifier,
    enabledByFullSubscriptionProduct.identifier
  ].lt_set];
  OCMStub([(id)keychainStore dataForKey:@"productsAcquiredViaSubscriptionSet"
                                  error:[OCMArg anyObjectRef]])
      .andReturn(productsAcquiredViaSubscriptionSet);

  auto storeConfiguration =
      [[BZRStoreConfiguration alloc]
       initWithProductsListJSONFilePath:JSONFilePath productListDecryptionKey:nil
       keychainAccessGroup:nil expiredSubscriptionGracePeriod:6 applicationUserID:nil
       applicationBundleID:[[NSBundle mainBundle] bundleIdentifier] bundledApplicationsIDs:nil
       multiAppSubscriptionClassifier:nil useiCloudUserID:YES activatePeriodicValidation:NO];

  store = [[BZRStore alloc] initWithConfiguration:storeConfiguration];
});

afterEach(^{
  [OHHTTPStubs removeAllStubs];
  keychainStore = nil;
  fileManager = nil;
  paymentQueue = nil;
  timeProvider = nil;
  dataMock = nil;
});

it(@"should allow no products when there is an invalid receipt validation status", ^{
  auto invalidReceiptValidationStatus = [[BZRReceiptValidationStatus alloc] initWithDictionary:@{
    @instanceKeypath(BZRReceiptValidationStatus, isValid): @NO,
    @instanceKeypath(BZRReceiptValidationStatus, error): $(BZRReceiptValidationErrorUnknown),
    @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date],
    @instanceKeypath(BZRReceiptValidationStatus, requestId): @"invalid bar"
  } error:nil];
  BZRStubHTTPClientToReturnReceiptValidationStatus(invalidReceiptValidationStatus);

  expect([store validateReceipt]).will.finish();

  expect(store.allowedProducts).will.beEmpty();
});

it(@"should allow no products when validatricks says that the receipt contains no products", ^{
  auto emptyReceiptValidationStatus = BZREmptyReceiptValidationStatus();
  BZRStubHTTPClientToReturnReceiptValidationStatus(emptyReceiptValidationStatus);

  expect([store validateReceipt]).will.complete();

  expect(store.allowedProducts).will.beEmpty();
});

it(@"should allow purchased products", ^{
  auto singleProductValidationStatus =
      [BZREmptyReceiptValidationStatus()
       modelByOverridingPropertyAtKeypath:
       @instanceKeypath(BZRReceiptValidationStatus, receipt.inAppPurchases)
       withValue:@[BZRReceiptInAppPurchaseInfoWithProductID(purchasedProduct.identifier)]];

  BZRStubHTTPClientToReturnReceiptValidationStatus(singleProductValidationStatus);

  expect([store validateReceipt]).will.complete();

  expect(store.allowedProducts).will.equal(@[purchasedProduct.identifier].lt_set);
});

it(@"should allow partial subscription products", ^{
  auto partialSubscriptionValidationStatus =
      BZRReceiptValidationStatusWithSubscriptionIdentifier(partialSubscriptionProduct.identifier);
  BZRStubHTTPClientToReturnReceiptValidationStatus(partialSubscriptionValidationStatus);

  expect([store validateReceipt]).will.complete();

  expect(store.allowedProducts).will
      .equal(@[enabledByPartialSubscriptionProduct.identifier].lt_set);
});

it(@"should allow partial subscription products and purchased products", ^{
  auto partialSubscriptionWithPurchasedProductValidationStatus =
      [BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(purchasedProduct.identifier, NO)
       modelByOverridingPropertyAtKeypath:
       @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription)
       withValue:BZRSubscriptionWithIdentifier(partialSubscriptionProduct.identifier)];
  BZRStubHTTPClientToReturnReceiptValidationStatus(
      partialSubscriptionWithPurchasedProductValidationStatus);

  expect([store validateReceipt]).will.complete();

  expect(store.allowedProducts).will
      .equal(@[purchasedProduct.identifier, enabledByPartialSubscriptionProduct.identifier].lt_set);
});

it(@"should allow all non-consumable products in full subscription", ^{
  auto fullSubscriptionValidationStatus =
      BZRReceiptValidationStatusWithSubscriptionIdentifier(fullSubscriptionProduct.identifier);
  BZRStubHTTPClientToReturnReceiptValidationStatus(fullSubscriptionValidationStatus);

  expect([store validateReceipt]).will.complete();

  expect(store.allowedProducts).will.equal(@[
    purchasedProduct.identifier,
    notPurchasedProduct.identifier,
    enabledByPartialSubscriptionProduct.identifier,
    enabledByFullSubscriptionProduct.identifier
  ].lt_set);
});

it(@"should allow all non-consumable products if there is a subscription that does not appear in"
    "the list", ^{
  auto fullSubscriptionValidationStatus =
      BZRReceiptValidationStatusWithSubscriptionIdentifier(@"not in product list subscription");
  BZRStubHTTPClientToReturnReceiptValidationStatus(fullSubscriptionValidationStatus);

  expect([store validateReceipt]).will.complete();

  expect(store.allowedProducts).will.equal(@[
    purchasedProduct.identifier,
    notPurchasedProduct.identifier,
    enabledByPartialSubscriptionProduct.identifier,
    enabledByFullSubscriptionProduct.identifier
  ].lt_set);
});

SpecEnd
