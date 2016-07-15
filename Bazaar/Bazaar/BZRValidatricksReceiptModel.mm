// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksReceiptModel.h"

#import "BZRReceiptEnvironment.h"
#import "NSValueTransformer+Validatricks.h"

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

+ (NSValueTransformer *)originalPurchaseDateTimeJSONTransformer {
  return [NSValueTransformer bzr_timeIntervalSince1970ValueTransformer];
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
        @"cancellationDateTime"
  };
}

+ (NSValueTransformer *)originalPurchaseDateTimeJSONTransformer {
  return [NSValueTransformer bzr_timeIntervalSince1970ValueTransformer];
}

+ (NSValueTransformer *)lastPurchaseDateTimeJSONTransformer {
  return [NSValueTransformer bzr_timeIntervalSince1970ValueTransformer];
}

+ (NSValueTransformer *)expirationDateTimeJSONTransformer {
  return [NSValueTransformer bzr_timeIntervalSince1970ValueTransformer];
}

+ (NSValueTransformer *)cancellationDateTimeJSONTransformer {
  return [NSValueTransformer bzr_timeIntervalSince1970ValueTransformer];
}

@end

#pragma mark -
#pragma mark BZRValidatricksReceiptInfo
#pragma mark -

@implementation BZRValidatricksReceiptInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRValidatricksReceiptInfo, environment): @"environment",
    @instanceKeypath(BZRValidatricksReceiptInfo, inAppPurchases): @"inAppPurchases",
    @instanceKeypath(BZRValidatricksReceiptInfo, subscription): @"subscription"
  };
}

+ (NSValueTransformer *)environmentJSONTransformer {
  return [NSValueTransformer bzr_validatricksReceiptEnvironmentValueTransformer];
}

+ (NSValueTransformer *)inAppPurchasesJSONTransformer {
  return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:
          [BZRValidatricksReceiptInAppPurchaseInfo class]];
}

+ (NSValueTransformer *)subscriptionJSONTransformer {
  return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:
          [BZRValidatricksReceiptSubscriptionInfo class]];
}

@end

NS_ASSUME_NONNULL_END
