// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRReceiptModel+GenericSubscription.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRReceiptSubscriptionInfo (GenericSubscription)

+ (BZRReceiptSubscriptionInfo *)genericActiveSubscriptionWithPendingRenewalInfo {
  return [BZRReceiptSubscriptionInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptSubscriptionInfo, productId): @"Generic active subscription",
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId): @"000000",
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime):
        [NSDate dateWithTimeIntervalSince1970:1337],
    @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime):
        [NSDate dateWithTimeIntervalSince1970:2337],
    @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired): @NO,
    @instanceKeypath(BZRReceiptSubscriptionInfo, pendingRenewalInfo):
        [BZRReceiptSubscriptionInfo createGenericPendingRenewalInfo]
  } error:nil];
}

+ (BZRSubscriptionPendingRenewalInfo *)createGenericPendingRenewalInfo {
  return [[BZRSubscriptionPendingRenewalInfo alloc] initWithDictionary:@{
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, willAutoRenew): @YES,
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, expectedRenewalProductId): @"",
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, isPendingPriceIncreaseConsent): @YES,
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, expirationReason):
        @(BZRSubscriptionExpirationReasonUnknownError),
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, isInBillingRetryPeriod): @NO
  }error:nil];
}

@end

NS_ASSUME_NONNULL_END
