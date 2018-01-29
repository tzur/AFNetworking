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
#pragma mark BZRSubscriptionPendingRenewalInfo
#pragma mark -

/// Enumerates a set of possible reasons for a subscription to stop being automatically renewed.
LTEnumDeclare(NSUInteger, BZRSubscriptionExpirationReason,
  /// Subscription auto-renewal stopped since it was manually discontinued by the user.
  BZRSubscriptionExpirationReasonDiscontinuedByUser,
  /// Subscription auto-renewal stopped due to billing issues.
  BZRSubscriptionExpirationReasonBillingError,
  /// Subscription auto-renewal stopped because the user did not agree to price increase.
  BZRSubscriptionExpirationReasonPriceChangeNotAgreed,
  /// Subscription auto-renewal stopped because the product was not available at the time of the
  /// renewal.
  BZRSubscriptionExpirationReasonProductWasUnavailable,
  /// Subscription auto-renewal stopped due to an unknown error.
  BZRSubscriptionExpirationReasonUnknownError
);

/// Describes the renewal status of a subscription product.
@interface BZRSubscriptionPendingRenewalInfo : BZRModel <NSSecureCoding>

/// \c YES if the subscription will auto-renew. If the value is \c YES then
/// \c expectedRenewalProductId will specify the product identifier of the subscription that will
/// auto-renew, otherwise check the \c isPendingPriceIncreaseConsent and \c expirationReason
/// properties to figure out why the subscription will not auto-renew.
@property (readonly, nonatomic) BOOL willAutoRenew;

/// Product identifier of the subscription that will auto-renew, or \c nil if subscription will not
/// auto-renew.
@property (readonly, nonatomic, nullable) NSString *expectedRenewalProductId;

/// \c YES if there was a price increase and the user has not agreed to it yet. If this is \c YES
/// then the subscription is expected to not auto-renew unless the user agrees to the price
/// increase.
@property (readonly, nonatomic) BOOL isPendingPriceIncreaseConsent;

/// In case the subscription is already expired this will specify the expiration reason, otherwise
/// it will be \c nil.
@property (readonly, nonatomic, nullable) BZRSubscriptionExpirationReason *expirationReason;

/// \c YES if the subscription was not renewed due to billing issues and Apple is still trying to
/// renew the subscription, \c NO otherwise.
@property (readonly, nonatomic) BOOL isInBillingRetryPeriod;

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

/// Renewal information for this subscription.
@property (readonly, nonatomic, nullable) BZRSubscriptionPendingRenewalInfo *pendingRenewalInfo;

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
