// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptModel.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRReceiptInAppPurchaseInfo
#pragma mark -

@implementation BZRReceiptInAppPurchaseInfo

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end

#pragma mark -
#pragma mark BZRSubscriptionPendingRenewalInfo
#pragma mark -

LTEnumImplement(NSUInteger, BZRSubscriptionExpirationReason,
  BZRSubscriptionExpirationReasonDiscontinuedByUser,
  BZRSubscriptionExpirationReasonBillingError,
  BZRSubscriptionExpirationReasonPriceChangeNotAgreed,
  BZRSubscriptionExpirationReasonProductWasUnavailable,
  BZRSubscriptionExpirationReasonUnknownError
);

@implementation BZRSubscriptionPendingRenewalInfo

+ (NSSet<NSString *> *)optionalPropertyKeys {
  static NSSet<NSString *> *optionalPropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    optionalPropertyKeys = [NSSet setWithArray:@[
      @instanceKeypath(BZRSubscriptionPendingRenewalInfo, expectedRenewalProductId),
      @instanceKeypath(BZRSubscriptionPendingRenewalInfo, isPendingPriceIncreaseConsent),
      @instanceKeypath(BZRSubscriptionPendingRenewalInfo, expirationReason),
      @instanceKeypath(BZRSubscriptionPendingRenewalInfo, isInBillingRetryPeriod)
    ]];
  });

  return optionalPropertyKeys;
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end

#pragma mark -
#pragma mark BZRReceiptSubscriptionInfo
#pragma mark -

@implementation BZRReceiptSubscriptionInfo

+ (NSSet<NSString *> *)optionalPropertyKeys {
  static NSSet<NSString *> *optionalPropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    optionalPropertyKeys = [NSSet setWithArray:@[
      @instanceKeypath(BZRReceiptSubscriptionInfo, lastPurchaseDateTime),
      @instanceKeypath(BZRReceiptSubscriptionInfo, cancellationDateTime),
      @instanceKeypath(BZRReceiptSubscriptionInfo, pendingRenewalInfo)
    ]];
  });

  return optionalPropertyKeys;
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end

#pragma mark -
#pragma mark BZRReceiptInfo
#pragma mark -

@implementation BZRReceiptInfo

+ (NSSet<NSString *> *)optionalPropertyKeys {
  static NSSet<NSString *> *optionalPropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    optionalPropertyKeys = [NSSet setWithArray:@[
      @instanceKeypath(BZRReceiptInfo, originalPurchaseDateTime),
      @instanceKeypath(BZRReceiptInfo, inAppPurchases),
      @instanceKeypath(BZRReceiptInfo, subscription)
    ]];
  });

  return optionalPropertyKeys;
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end

NS_ASSUME_NONNULL_END
