// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptModel.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRValidatricksReceiptInAppPurchaseInfo
#pragma mark -

/// Extends \c BZRReceiptInAppPurchaseInfo by providing instant deserialization from Validatricks
/// JSON response.
@interface BZRValidatricksReceiptInAppPurchaseInfo : BZRReceiptInAppPurchaseInfo
@end

#pragma mark -
#pragma mark BZRValidatricksSubscriptionPendingRenewalInfo
#pragma mark -

@interface BZRValidatricksSubscriptionPendingRenewalInfo : BZRSubscriptionPendingRenewalInfo
@end

#pragma mark -
#pragma mark BZRValidatricksReceiptSubscriptionInfo
#pragma mark -

/// Extends \c BZRReceiptSubscriptionInfo by providing instant deserialization from Validatricks
/// JSON response.
@interface BZRValidatricksReceiptSubscriptionInfo : BZRReceiptSubscriptionInfo
@end

#pragma mark -
#pragma mark BZRValidatricksReceiptInfo
#pragma mark -

/// Extends \c BZRReceiptInfo by providing instant deserialization from Validatricks
/// JSON response.
@interface BZRValidatricksReceiptInfo : BZRReceiptInfo
@end

NS_ASSUME_NONNULL_END
