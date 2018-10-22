// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptModel.h"

#import "BZRReceiptEnvironment.h"
#import "NSValueTransformer+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRReceiptTransactionInfo
#pragma mark -

@implementation BZRReceiptTransactionInfo

+ (NSSet<NSString *> *)optionalPropertyKeys {
  static NSSet<NSString *> *optionalPropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    optionalPropertyKeys = [NSSet setWithArray:@[
        @instanceKeypath(BZRReceiptTransactionInfo, expirationDateTime),
        @instanceKeypath(BZRReceiptTransactionInfo, cancellationDateTime)
    ]];
  });

  return optionalPropertyKeys;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRReceiptTransactionInfo, productId): @"productId",
    @instanceKeypath(BZRReceiptTransactionInfo, transactionId): @"transactionId",
    @instanceKeypath(BZRReceiptTransactionInfo, purchaseDateTime): @"purchaseDateTime",
    @instanceKeypath(BZRReceiptTransactionInfo, originalTransactionId): @"originalTransactionId",
    @instanceKeypath(BZRReceiptTransactionInfo, originalPurchaseDateTime):
        @"originalPurchaseDateTime",
    @instanceKeypath(BZRReceiptTransactionInfo, quantity): @"quantity",
    @instanceKeypath(BZRReceiptTransactionInfo, expirationDateTime): @"expiresDateTime",
    @instanceKeypath(BZRReceiptTransactionInfo, cancellationDateTime): @"cancellationDateTime",
    @instanceKeypath(BZRReceiptTransactionInfo, isTrialPeriod): @"isTrialPeriod",
    @instanceKeypath(BZRReceiptTransactionInfo, isIntroOfferPeriod): @"isIntroOfferPeriod"
  };
}

+ (NSValueTransformer *)purchaseDateTimeJSONTransformer {
  return [NSValueTransformer bzr_millisecondsDateTimeValueTransformer];
}

+ (NSValueTransformer *)originalPurchaseDateTimeJSONTransformer {
  return [NSValueTransformer bzr_millisecondsDateTimeValueTransformer];
}

+ (NSValueTransformer *)expirationDateTimeJSONTransformer {
  return [NSValueTransformer bzr_millisecondsDateTimeValueTransformer];
}

+ (NSValueTransformer *)cancellationDateTimeJSONTransformer {
  return [NSValueTransformer bzr_millisecondsDateTimeValueTransformer];
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end

#pragma mark -
#pragma mark BZRReceiptInAppPurchaseInfo
#pragma mark -

@implementation BZRReceiptInAppPurchaseInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, productId): @"productId",
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, originalTransactionId):
        @"originalTransactionId",
    @instanceKeypath(BZRReceiptInAppPurchaseInfo, originalPurchaseDateTime):
        @"originalPurchaseDateTime",
  };
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
  return @{
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, willAutoRenew):
        @"willAutoRenew",
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, expectedRenewalProductId):
        @"expectedRenewalProductId",
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, isPendingPriceIncreaseConsent):
        @"isPendingPriceIncreaseConsent",
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, expirationReason):
        @"expirationReason",
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, isInBillingRetryPeriod):
        @"isInBillingRetryPeriod"
  };
}

+ (NSValueTransformer *)expirationReasonJSONTransformer {
  return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
    @"discontinuedByUser": $(BZRSubscriptionExpirationReasonDiscontinuedByUser),
    @"billingError": $(BZRSubscriptionExpirationReasonBillingError),
    @"priceIncreased": $(BZRSubscriptionExpirationReasonPriceChangeNotAgreed),
    @"productWasUnavailable": $(BZRSubscriptionExpirationReasonProductWasUnavailable),
    @"unknownError": $(BZRSubscriptionExpirationReasonUnknownError)
  } defaultValue:$(BZRSubscriptionExpirationReasonUnknownError)
    reverseDefaultValue:@"unknownError"];
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
  return @{
    @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired): @"expired",
    @instanceKeypath(BZRReceiptSubscriptionInfo, productId): @"productId",
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId):
        @"originalTransactionId",
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime):
        @"originalPurchaseDateTime",
    @instanceKeypath(BZRReceiptSubscriptionInfo, lastPurchaseDateTime):
        @"lastPurchaseDateTime",
    @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime):
        @"expiresDateTime",
    @instanceKeypath(BZRReceiptSubscriptionInfo, cancellationDateTime):
        @"cancellationDateTime",
    @instanceKeypath(BZRReceiptSubscriptionInfo, pendingRenewalInfo):
        @"pendingRenewalInfo"
  };
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
      @instanceKeypath(BZRReceiptInfo, subscription),
      @instanceKeypath(BZRReceiptInfo, transactions)
    ]];
  });

  return optionalPropertyKeys;
}

+ (NSDictionary<NSString *, id> *)defaultPropertyValues {
  static NSDictionary<NSString *, id> *defaultPropertyValues;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultPropertyValues = @{
      @instanceKeypath(BZRReceiptInfo, transactions): @[]
    };
  });

  return defaultPropertyValues;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRReceiptInfo, environment): @"environment",
    @instanceKeypath(BZRReceiptInfo, originalPurchaseDateTime): @"originalPurchaseDateTime",
    @instanceKeypath(BZRReceiptInfo, inAppPurchases): @"inAppPurchases",
    @instanceKeypath(BZRReceiptInfo, subscription): @"subscription",
    @instanceKeypath(BZRReceiptInfo, transactions): @"transactions"
  };
}

+ (NSValueTransformer *)environmentJSONTransformer {
  return [NSValueTransformer bzr_validatricksReceiptEnvironmentValueTransformer];
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

+ (NSValueTransformer *)transactionsJSONTransformer {
  return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:
      [BZRReceiptTransactionInfo class]];
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

@end

NS_ASSUME_NONNULL_END
