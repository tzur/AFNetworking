// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptEnvironment;

#pragma mark -
#pragma mark BZRReceiptInAppPurchaseInfo
#pragma mark -

/// Describes a single in-app purchase that is listed in an application receipt.
@interface BZRReceiptInAppPurchaseInfo : BZRModel <NSSecureCoding>

/// iTune-Connect product ID of the IAP.
@property (readonly, nonatomic) NSString *productId;

/// ID of the transaction in which the user has purchased the IAP.
@property (readonly, nonatomic) NSString *originalTransactionId;

/// Date and time when the IAP was originally purchased.
@property (readonly, nonatomic) NSDate *originalPurchaseDateTime;

@end

#pragma mark -
#pragma mark BZRReceiptSubscriptionInfo
#pragma mark -

/// Describes the subscription status as listed in a receipt.
@interface BZRReceiptSubscriptionInfo : BZRModel <NSSecureCoding>

/// iTunes-Connect product ID of the subscription.
@property (readonly, nonatomic) NSString *productId;

/// ID of the transaction in which the user has purchased the subscription.
@property (readonly, nonatomic) NSString *originalTransactionId;

/// Date and time when the subscription was originally purchased.
@property (readonly, nonatomic) NSDate *originalPurchaseDateTime;

/// Date and time of the latest subscription renewal or \c nil if no renewals issued.
@property (readonly, nonatomic, nullable) NSDate *lastPurchaseDateTime;

/// Date and time of the subscription expiration.
@property (readonly, nonatomic) NSDate *expirationDateTime;

/// Date and time of the subscription cancellation or \c nil if it was not cancelled.
@property (readonly, nonatomic, nullable) NSDate *cancellationDateTime;

/// \c YES if the subscription has already expired.
@property (readonly, nonatomic) BOOL isExpired;

@end

#pragma mark -
#pragma mark BZRReceiptInfo
#pragma mark -

/// Contains crucial information that is extracted from application receipt.
@interface BZRReceiptInfo : BZRModel <NSSecureCoding>

/// The environment that the receipt was issued for.
@property (readonly, nonatomic) BZRReceiptEnvironment *environment;

/// Date and time the application was originally acquired from the AppStore.
@property (readonly, nonatomic, nullable) NSDate *originalPurchaseDateTime;

/// List of all non-subscription in-app purchases made by the user.
@property (readonly, nonatomic, nullable) NSArray<BZRReceiptInAppPurchaseInfo *> *inAppPurchases;

/// Subscription information.
@property (readonly, nonatomic, nullable) BZRReceiptSubscriptionInfo *subscription;

@end

NS_ASSUME_NONNULL_END
