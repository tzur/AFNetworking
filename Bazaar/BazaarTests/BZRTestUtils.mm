// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRTestUtils.h"

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
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId): @"bar",
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime): [NSDate date],
    @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime):
        [NSDate dateWithTimeIntervalSinceNow:1337],
    @instanceKeypath(BZRReceiptSubscriptionInfo, cancellationDateTime) :
        cancelled ? [NSDate dateWithTimeIntervalSinceNow:1337 / 2] : [NSNull null],
    @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired): @(expiry)
  } error:nil];
  BZRReceiptInfo *receipt = [BZRReceiptInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptInfo, environment): $(BZRReceiptEnvironmentProduction),
    @instanceKeypath(BZRReceiptInfo, subscription): subscription
  } error:nil];
  return [BZRReceiptValidationStatus modelWithDictionary:@{
    @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
    @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date],
    @instanceKeypath(BZRReceiptValidationStatus, receipt): receipt
  } error:nil];
}

BZRReceiptValidationStatus *BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(
    NSString *identifier, BOOL expiry) {
  BZRReceiptValidationStatus *receiptValidationStatus =
      BZRReceiptValidationStatusWithExpiry(expiry);
  BZRReceiptInAppPurchaseInfo *inAppPurchase = [BZRReceiptInAppPurchaseInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, productId): identifier,
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, originalTransactionId): @"bar",
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, originalPurchaseDateTime): [NSDate date],
  } error:nil];
  BZRReceiptInfo *receipt =
      [receiptValidationStatus.receipt
       modelByOverridingProperty:@keypath(receiptValidationStatus.receipt, inAppPurchases)
                       withValue:@[inAppPurchase]];
  return [receiptValidationStatus
          modelByOverridingProperty:@keypath(receiptValidationStatus, receipt)
                          withValue:receipt];
}

NS_ASSUME_NONNULL_END
