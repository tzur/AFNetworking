// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRTestUtils.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRContentFetcherParameters.h"
#import "BZRProduct.h"
#import "BZRReceiptEnvironment.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"

NS_ASSUME_NONNULL_BEGIN

BZRProduct *BZRProductWithIdentifierAndContent(NSString *identifier) {
  return BZRProductWithIdentifierAndParameters(identifier,
                                               OCMClassMock([BZRContentFetcherParameters class]));
}

BZRProduct *BZRProductWithIdentifier(NSString *identifier) {
  return BZRProductWithIdentifierAndParameters(identifier, nil);
}

BZRProduct *BZRProductWithIdentifierAndParameters(NSString *identifier,
    BZRContentFetcherParameters * _Nullable parameters) {
  NSDictionary *contentFetcherParametersDictionary = parameters ?
      @{@instanceKeypath(BZRProduct, contentFetcherParameters): parameters} : @{};
  NSDictionary *dictionaryValue = [@{
    @instanceKeypath(BZRProduct, identifier): identifier,
    @instanceKeypath(BZRProduct, productType): $(BZRProductTypeNonConsumable),
    @instanceKeypath(BZRProduct, isSubscribersOnly): @NO,
  } mtl_dictionaryByAddingEntriesFromDictionary:contentFetcherParametersDictionary];

  return [[BZRProduct alloc] initWithDictionary:dictionaryValue error:nil];
}

BZRReceiptValidationStatus *BZRReceiptValidationStatusWithExpiry(BOOL expiry, BOOL cancelled) {
  BZRReceiptSubscriptionInfo *subscription = [BZRReceiptSubscriptionInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptSubscriptionInfo, productId): @"foo",
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId): @"000000",
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime):
        [NSDate dateWithTimeIntervalSince1970:1337],
    @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime):
        [NSDate dateWithTimeIntervalSince1970:2337],
    @instanceKeypath(BZRReceiptSubscriptionInfo, cancellationDateTime) :
        cancelled ? [NSDate dateWithTimeIntervalSince1970:2337 / 2] : [NSNull null],
    @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired): @(expiry)
  } error:nil];
  BZRReceiptInfo *receipt = [BZRReceiptInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptInfo, environment): $(BZRReceiptEnvironmentProduction),
    @instanceKeypath(BZRReceiptInfo, subscription): subscription
  } error:nil];
  return [BZRReceiptValidationStatus modelWithDictionary:@{
    @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
    @instanceKeypath(BZRReceiptValidationStatus, validationDateTime):
        [NSDate dateWithTimeIntervalSince1970:1337],
    @instanceKeypath(BZRReceiptValidationStatus, receipt): receipt
  } error:nil];
}

BZRReceiptValidationStatus *BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(
    NSString *identifier, BOOL expiry) {
  BZRReceiptValidationStatus *receiptValidationStatus =
      BZRReceiptValidationStatusWithExpiry(expiry);
  BZRReceiptInAppPurchaseInfo *inAppPurchase = [BZRReceiptInAppPurchaseInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, productId): identifier,
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, originalTransactionId): @"000000",
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, originalPurchaseDateTime):
        [NSDate dateWithTimeIntervalSince1970:1337]
  } error:nil];
  return [receiptValidationStatus
      modelByOverridingPropertyAtKeypath:@keypath(receiptValidationStatus, receipt.inAppPurchases)
                               withValue:@[inAppPurchase]];
}

BZRReceiptValidationStatus *BZRReceiptValidationStatusWithSubscriptionIdentifier
    (NSString *subscriptionIdentifier) {
  BZRReceiptValidationStatus *receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
  BZRReceiptSubscriptionInfo *subscription = [BZRReceiptSubscriptionInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptSubscriptionInfo, productId): subscriptionIdentifier,
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId): @"000000",
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime):
        [NSDate dateWithTimeIntervalSince1970:1337],
    @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime):
        [NSDate dateWithTimeIntervalSince1970:2337],
    @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired): @NO
  } error:nil];
  return [receiptValidationStatus
          modelByOverridingPropertyAtKeypath:@keypath(receiptValidationStatus, receipt.subscription)
                                   withValue:subscription];
}

SKProduct *BZRSKProductWithProperties(NSString *identifier, NSDecimalNumber *price,
    NSString *localeIdentifier) {
  SKProduct *product = OCMClassMock([SKProduct class]);
  OCMStub([product productIdentifier]).andReturn(identifier);
  OCMStub([product priceLocale]).andReturn([NSLocale localeWithLocaleIdentifier:localeIdentifier]);
  OCMStub([product price]).andReturn(price);
  return product;
}

SKProductsResponse *BZRProductsResponseWithSKProducts(NSArray<SKProduct *> *products) {
  SKProductsResponse *response = OCMClassMock([SKProductsResponse class]);
  OCMStub([response products]).andReturn(products);

  return response;
}

SKProductsResponse *BZRProductsResponseWithProduct(NSString *productIdentifier) {
  SKProduct *product = BZRSKProductWithProperties(productIdentifier);
  return BZRProductsResponseWithSKProducts(@[product]);
}

SKProductsResponse *BZRProductsResponseWithProducts(NSArray<NSString *> *productIdentifiers) {
  NSArray<SKProduct *> *products = [productIdentifiers lt_map:^SKProduct *(NSString *identifier) {
    return BZRSKProductWithProperties(identifier);
  }];
  return BZRProductsResponseWithSKProducts(products);
}

NS_ASSUME_NONNULL_END
