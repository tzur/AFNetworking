// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksReceiptModel.h"

#import "NSValueTransformer+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRValidatricksReceiptInAppPurchaseInfo
#pragma mark -

@implementation BZRValidatricksReceiptInAppPurchaseInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo, productId): @"productId",
    @instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo, originalTransactionId):
        @"originalTransactionId",
    @instanceKeypath(BZRValidatricksReceiptInAppPurchaseInfo, originalPurchaseDateTime):
        @"originalPurchaseDateTime",
  };
}

@end

#pragma mark -
#pragma mark BZRValidatricksSubscriptionPendingRenewalInfo
#pragma mark -

@implementation BZRValidatricksSubscriptionPendingRenewalInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRValidatricksSubscriptionPendingRenewalInfo, willAutoRenew):
        @"willAutoRenew",
    @instanceKeypath(BZRValidatricksSubscriptionPendingRenewalInfo, expectedRenewalProductId):
        @"expectedRenewalProductId",
    @instanceKeypath(BZRValidatricksSubscriptionPendingRenewalInfo, isPendingPriceIncreaseConsent):
        @"isPendingPriceIncreaseConsent",
    @instanceKeypath(BZRValidatricksSubscriptionPendingRenewalInfo, expirationReason):
        @"expirationReason",
    @instanceKeypath(BZRValidatricksSubscriptionPendingRenewalInfo, isInBillingRetryPeriod):
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

@end

#pragma mark -
#pragma mark BZRValidatricksReceiptSubscriptionInfo
#pragma mark -

@implementation BZRValidatricksReceiptSubscriptionInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, isExpired): @"expired",
    @instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, productId): @"productId",
    @instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, originalTransactionId):
        @"originalTransactionId",
    @instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, originalPurchaseDateTime):
        @"originalPurchaseDateTime",
    @instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, lastPurchaseDateTime):
        @"lastPurchaseDateTime",
    @instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, expirationDateTime):
        @"expiresDateTime",
    @instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, cancellationDateTime):
        @"cancellationDateTime",
    @instanceKeypath(BZRValidatricksReceiptSubscriptionInfo, pendingRenewalInfo):
        @"pendingRenewalInfo"
  };
}

+ (NSValueTransformer *)pendingRenewalInfoJSONTransformer {
  return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:
          [BZRValidatricksSubscriptionPendingRenewalInfo class]];
}

@end

#pragma mark -
#pragma mark BZRValidatricksReceiptInfo
#pragma mark -

@implementation BZRValidatricksReceiptInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRValidatricksReceiptInfo, environment): @"environment",
    @instanceKeypath(BZRValidatricksReceiptInfo, originalPurchaseDateTime):
        @"originalPurchaseDateTime",
    @instanceKeypath(BZRValidatricksReceiptInfo, inAppPurchases): @"inAppPurchases",
    @instanceKeypath(BZRValidatricksReceiptInfo, subscription): @"subscription"
  };
}

+ (NSValueTransformer *)inAppPurchasesJSONTransformer {
  return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:
          [BZRValidatricksReceiptInAppPurchaseInfo class]];
}

+ (NSValueTransformer *)subscriptionJSONTransformer {
  return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:
          [BZRValidatricksReceiptSubscriptionInfo class]];
}

+ (NSValueTransformer *)environmentJSONTransformer {
  return [NSValueTransformer bzr_validatricksReceiptEnvironmentValueTransformer];
}

@end

NS_ASSUME_NONNULL_END
