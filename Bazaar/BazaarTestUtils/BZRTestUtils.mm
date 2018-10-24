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

BZRProduct *BZRProductWithIdentifierAndType(NSString *identifier, BZRProductType *productType) {
  return [[BZRProduct alloc] initWithDictionary:@{
    @instanceKeypath(BZRProduct, identifier): identifier,
    @instanceKeypath(BZRProduct, productType): productType,
    @instanceKeypath(BZRProduct, isSubscribersOnly): @NO
  } error:nil];
}

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

BZRReceiptValidationStatus *BZREmptyReceiptValidationStatus() {
  auto receipt = [BZRReceiptInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptInfo, environment): $(BZRReceiptEnvironmentProduction),
    @instanceKeypath(BZRReceiptInfo, transactions): @[]
  } error:nil];
  return [BZRReceiptValidationStatus modelWithDictionary:@{
    @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
    @instanceKeypath(BZRReceiptValidationStatus, validationDateTime):
        [NSDate dateWithTimeIntervalSince1970:1337],
    @instanceKeypath(BZRReceiptValidationStatus, receipt): receipt
  } error:nil];
}

BZRReceiptValidationStatus *BZRReceiptValidationStatusWithExpiry(BOOL expiry, BOOL cancelled) {
  auto subscription = BZRSubscriptionWithIdentifier(@"foo", expiry, cancelled);
  auto transactionInfo = [BZRReceiptTransactionInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptTransactionInfo, productId): @"foo",
    @instanceKeypath(BZRReceiptTransactionInfo, transactionId): @"0001337",
    @instanceKeypath(BZRReceiptTransactionInfo, purchaseDateTime):
        [NSDate dateWithTimeIntervalSince1970:2337],
    @instanceKeypath(BZRReceiptTransactionInfo, originalTransactionId): @"000000",
    @instanceKeypath(BZRReceiptTransactionInfo, originalPurchaseDateTime):
        [NSDate dateWithTimeIntervalSince1970:1337],
    @instanceKeypath(BZRReceiptTransactionInfo, quantity): @13,
    @instanceKeypath(BZRReceiptTransactionInfo, isTrialPeriod): @NO,
    @instanceKeypath(BZRReceiptTransactionInfo, isIntroOfferPeriod): @NO
  } error:nil];
  auto receipt = [BZRReceiptInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptInfo, environment): $(BZRReceiptEnvironmentProduction),
    @instanceKeypath(BZRReceiptInfo, subscription): subscription,
    @instanceKeypath(BZRReceiptInfo, transactions): @[transactionInfo]
  } error:nil];
  return [BZRReceiptValidationStatus modelWithDictionary:@{
    @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
    @instanceKeypath(BZRReceiptValidationStatus, validationDateTime):
        [NSDate dateWithTimeIntervalSince1970:1337],
    @instanceKeypath(BZRReceiptValidationStatus, receipt): receipt,
    @instanceKeypath(BZRReceiptValidationStatus, requestId): @"foo.request.id"
  } error:nil];
}

BZRReceiptValidationStatus *BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(
    NSString *identifier, BOOL expiry) {
  auto receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(expiry);
  auto inAppPurchase = BZRReceiptInAppPurchaseInfoWithProductID(identifier);
  return [receiptValidationStatus
      modelByOverridingPropertyAtKeypath:@keypath(receiptValidationStatus, receipt.inAppPurchases)
                               withValue:@[inAppPurchase]];
}

BZRReceiptInAppPurchaseInfo *BZRReceiptInAppPurchaseInfoWithProductID(NSString *productID) {
  return [BZRReceiptInAppPurchaseInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, productId): productID,
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, originalTransactionId): @"000000",
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, originalPurchaseDateTime):
        [NSDate dateWithTimeIntervalSince1970:1337]
  } error:nil];
}

BZRReceiptValidationStatus *BZRReceiptValidationStatusWithSubscriptionIdentifier
    (NSString *subscriptionIdentifier) {
  BZRReceiptValidationStatus *receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
  auto subscription = BZRSubscriptionWithIdentifier(subscriptionIdentifier);
  return [receiptValidationStatus
          modelByOverridingPropertyAtKeypath:@keypath(receiptValidationStatus, receipt.subscription)
                                   withValue:subscription];
}

SKProduct *BZRMockedSKProductWithProperties(NSString *identifier, NSDecimalNumber *price,
    NSString *localeIdentifier) {
  SKProduct *product = OCMClassMock([SKProduct class]);
  OCMStub([product productIdentifier]).andReturn(identifier);
  OCMStub([product priceLocale]).andReturn([NSLocale localeWithLocaleIdentifier:localeIdentifier]);
  OCMStub([product price]).andReturn(price);
  return product;
}

SKProductsResponse *BZRMockedProductsResponseWithSKProducts(NSArray<SKProduct *> *products) {
  SKProductsResponse *response = OCMClassMock([SKProductsResponse class]);
  OCMStub([response products]).andReturn(products);

  return response;
}

SKProductsResponse *BZRMockedProductsResponseWithProduct(NSString *productIdentifier) {
  auto product = BZRMockedSKProductWithProperties(productIdentifier);
  return BZRMockedProductsResponseWithSKProducts(@[product]);
}

SKProductsResponse *BZRMockedProductsResponseWithProducts(NSArray<NSString *> *productIdentifiers) {
  NSArray<SKProduct *> *products = [productIdentifiers lt_map:^SKProduct *(NSString *identifier) {
    return BZRMockedSKProductWithProperties(identifier);
  }];
  return BZRMockedProductsResponseWithSKProducts(products);
}

BZRReceiptTransactionInfo *BZRTransactionWithTransactionIdentifier(NSString *transactionId) {
  return [BZRReceiptTransactionInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptTransactionInfo, productId): @"foo",
    @instanceKeypath(BZRReceiptTransactionInfo, transactionId): transactionId,
    @instanceKeypath(BZRReceiptTransactionInfo, purchaseDateTime):
        [NSDate dateWithTimeIntervalSince1970:2337],
    @instanceKeypath(BZRReceiptTransactionInfo, originalTransactionId): @"00000",
    @instanceKeypath(BZRReceiptTransactionInfo, originalPurchaseDateTime):
        [NSDate dateWithTimeIntervalSince1970:1337],
    @instanceKeypath(BZRReceiptTransactionInfo, quantity): @13,
    @instanceKeypath(BZRReceiptTransactionInfo, isTrialPeriod): @NO,
    @instanceKeypath(BZRReceiptTransactionInfo, isIntroOfferPeriod): @NO
  } error:nil];
}

SKPaymentTransaction *BZRMockedSKPaymentTransaction(NSString *productID, NSString *transactionID,
     SKPaymentTransactionState state, NSDate *transactionDate) {
  SKPayment *payment = OCMClassMock(SKPayment.class);
  OCMStub([payment productIdentifier]).andReturn(productID);

  SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);

  OCMStub([transaction transactionDate]).andReturn(transactionDate);
  OCMStub([transaction transactionState]).andReturn(state);
  OCMStub([transaction transactionIdentifier]).andReturn(transactionID);
  OCMStub([transaction payment]).andReturn(payment);
  return transaction;
}

BZRReceiptSubscriptionInfo *BZRSubscriptionWithIdentifier(NSString *subscriptionIdentifier,
    BOOL expired, BOOL cancelled) {
  auto cancellationDateTimeOrNull =
      cancelled ? [NSDate dateWithTimeIntervalSince1970:2337] : [NSNull null];
  return [BZRReceiptSubscriptionInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptSubscriptionInfo, productId): subscriptionIdentifier,
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId): @"bar.transaction.id",
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime):
        [NSDate dateWithTimeIntervalSince1970:1337],
    @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime): [NSDate distantFuture],
    @instanceKeypath(BZRReceiptSubscriptionInfo, cancellationDateTime): cancellationDateTimeOrNull,
    @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired): @(expired)
  } error:nil];
}

NS_ASSUME_NONNULL_END
