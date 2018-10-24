// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptEnvironment;

#pragma mark -
#pragma mark BZRReceiptTransactionInfo
#pragma mark -

/// Describes a single transaction that is listed in an application receipt. The transaction can be
/// associated with an in-app purchase, a subscription purchase or a subscription renewal.
@interface BZRReceiptTransactionInfo : BZRModel <MTLJSONSerializing, NSSecureCoding>

/// iTunes-Connect product ID associated with the transaction.
@property (readonly, nonatomic) NSString *productId;

/// ID of the transaction associated with a purchase or renewal.
@property (readonly, nonatomic) NSString *transactionId;

/// Date and time of the purchase or renewal.
@property (readonly, nonatomic) NSDate *purchaseDateTime;

/// ID of the original transaction associated with a purchase.
@property (readonly, nonatomic) NSString *originalTransactionId;

/// Date and time of the purchase of the original transaction.
@property (readonly, nonatomic) NSDate *originalPurchaseDateTime;

/// Number of products that were purchased through the transaction.
@property (readonly, nonatomic) NSUInteger quantity;

/// Date and time of the subscription expiration. \c nil if the transaction is not associated with a
/// subscription product.
@property (readonly, nonatomic, nullable) NSDate *expirationDateTime;

/// Date and time of the subscription cancellation or \c nil if it was not cancelled or the
/// transaction is not associated with a subscription product.
@property (readonly, nonatomic, nullable) NSDate *cancellationDateTime;

/// \c YES if transaction is of a trial period, \c NO otherwise.
@property (readonly, nonatomic) BOOL isTrialPeriod;

/// \c YES if transaction is of an intro offer period, \c NO otherwise.
@property (readonly, nonatomic) BOOL isIntroOfferPeriod;

@end

#pragma mark -
#pragma mark BZRReceiptInAppPurchaseInfo
#pragma mark -

/// Describes a single in-app purchase that is listed in an application receipt.
@interface BZRReceiptInAppPurchaseInfo : BZRModel <MTLJSONSerializing, NSSecureCoding>

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
@interface BZRSubscriptionPendingRenewalInfo : BZRModel <MTLJSONSerializing, NSSecureCoding>

/// \c YES if the subscription will auto-renew. If the value is \c YES then
/// \c expectedRenewalProductId will specify the product identifier of the subscription that will
/// auto-renew, otherwise check the \c isPendingPriceIncreaseConsent and \c expirationReason
/// properties to figure out why the subscription will not auto-renew.
@property (readonly, nonatomic) BOOL willAutoRenew;

/// Product identifier of the subscription that will auto-renew. May be \c nil if subscription will
/// not auto-renew.
///
/// @note This property may contain a value even if the subscription will not auto-renew. Do not
/// test the value of this property in order to determine auto-renewal status, instead use the
/// \c willAutoRenew property.
@property (readonly, nonatomic, nullable) NSString *expectedRenewalProductId;

/// \c YES if there was a price increase and the user has not agreed to it yet. If this is \c YES
/// then the subscription is expected to not auto-renew unless the user agrees to the price
/// increase.
@property (readonly, nonatomic) BOOL isPendingPriceIncreaseConsent;

/// In case the subscription is already expired this will specify the expiration reason, otherwise
/// it will be \c nil.
///
/// @note This property may be \c nil even for expired subscriptions.
@property (readonly, nonatomic, nullable) BZRSubscriptionExpirationReason *expirationReason;

/// \c YES if the subscription was not renewed due to billing issues and Apple is still trying to
/// renew the subscription, \c NO otherwise.
@property (readonly, nonatomic) BOOL isInBillingRetryPeriod;

@end

#pragma mark -
#pragma mark BZRReceiptSubscriptionInfo
#pragma mark -

/// Describes the subscription status as listed in a receipt.
@interface BZRReceiptSubscriptionInfo : BZRModel <MTLJSONSerializing, NSSecureCoding>

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
@interface BZRReceiptInfo : BZRModel <MTLJSONSerializing, NSSecureCoding>

/// The environment that the receipt was issued for.
@property (readonly, nonatomic) BZRReceiptEnvironment *environment;

/// Array of transactions associated with purchases and renewals of the user.
@property (readonly, nonatomic) NSArray<BZRReceiptTransactionInfo *> *transactions;

/// Date and time the application was originally acquired from the AppStore.
@property (readonly, nonatomic, nullable) NSDate *originalPurchaseDateTime;

/// List of all non-subscription in-app purchases made by the user.
@property (readonly, nonatomic, nullable) NSArray<BZRReceiptInAppPurchaseInfo *> *inAppPurchases;

/// Subscription information.
@property (readonly, nonatomic, nullable) BZRReceiptSubscriptionInfo *subscription;

@end

NS_ASSUME_NONNULL_END
