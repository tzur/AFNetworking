// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptModel.h"

#import "BZRReceiptEnvironment.h"
#import "NSValueTransformer+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRReceiptInAppPurchaseInfo
#pragma mark -

@implementation BZRReceiptInAppPurchaseInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{};
}

+ (NSValueTransformer *)originalPurchaseDateTimeJSONTransformer {
  return [NSValueTransformer bzr_millisecondsDateTimeValueTransformer];
}

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

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{};
}

+ (NSValueTransformer *)expirationReasonJSONTransformer {
  return [NSValueTransformer bzr_enumNameTransformerForClass:
          [BZRSubscriptionExpirationReason class]];
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

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{};
}

+ (NSValueTransformer *)originalPurchaseDateTimeJSONTransformer {
  return [NSValueTransformer bzr_millisecondsDateTimeValueTransformer];
}

+ (NSValueTransformer *)lastPurchaseDateTimeJSONTransformer {
  return [NSValueTransformer bzr_millisecondsDateTimeValueTransformer];
}

+ (NSValueTransformer *)expirationDateTimeJSONTransformer {
  return [NSValueTransformer bzr_millisecondsDateTimeValueTransformer];
}

+ (NSValueTransformer *)cancellationDateTimeJSONTransformer {
  return [NSValueTransformer bzr_millisecondsDateTimeValueTransformer];
}

+ (NSValueTransformer *)pendingRenewalInfoJSONTransformer {
  return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:
          [BZRSubscriptionPendingRenewalInfo class]];
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

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{};
}

+ (NSValueTransformer *)environmentJSONTransformer {
  return [NSValueTransformer bzr_enumNameTransformerForClass:[BZRReceiptEnvironment class]];
}

+ (NSValueTransformer *)originalPurchaseDateTimeJSONTransformer {
  return [NSValueTransformer bzr_millisecondsDateTimeValueTransformer];
}

+ (NSValueTransformer *)inAppPurchasesJSONTransformer {
  return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:
          [BZRReceiptInAppPurchaseInfo class]];
}

+ (NSValueTransformer *)subscriptionJSONTransformer {
  return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:
          [BZRReceiptSubscriptionInfo class]];
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end

NS_ASSUME_NONNULL_END
