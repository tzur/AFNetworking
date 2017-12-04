// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptSubscriptionInfo, SPXSubscriptionDescriptor;

/// Represents the event where the user attempted to purchase a subscription.
@interface SPXPurchaseSubscriptionEvent : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c subscriptionDescriptor used to purchase the subscription,
/// \c successfulPurchase describing if the purchase was successful, \c receiptInfo describing the
/// receipt information received after the purchase, \c purchaseDuration is the duration of the
/// purchase process and \c error with an appropriate error on failure.
- (instancetype)initWithSubscriptionDescriptor:(SPXSubscriptionDescriptor *)subscriptionDescriptor
                            successfulPurchase:(BOOL)successfulPurchase
                                   receiptInfo:(nullable BZRReceiptSubscriptionInfo *)receiptInfo
                              purchaseDuration:(CFTimeInterval)purchaseDuration
                                         error:(nullable NSError *)error  NS_DESIGNATED_INITIALIZER;

/// Product unique identifier.
@property (readonly, nonatomic) NSString *productIdentifier;

/// Subscription price.
@property (readonly, nonatomic) NSDecimalNumber *price;

/// Identifier for the locale. For example "en_GB", "es_ES_PREEURO".
@property (readonly, nonatomic) NSString *localeIdentifier;

/// Item price three-letter currency code. For example "USD", "ILS", "RUB".
@property (readonly, nonatomic, nullable) NSString *currencyCode;

/// \c YES if the purchase was successful, \c NO otherwise.
@property (readonly, nonatomic) BOOL successfulPurchase;

/// ID of the transaction in which the user has purchased the subscription.
@property (readonly, nonatomic, nullable) NSString *originalTransactionId;

/// Duration of the purchase process.
@property (readonly, nonatomic) CFTimeInterval purchaseDuration;

/// Failure description if the purchase was unsuccessful, \c nil otherwise.
@property (readonly, nonatomic, nullable) NSString *failureDescription;

@end

NS_ASSUME_NONNULL_END
