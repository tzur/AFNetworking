// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

/// Describes available subscription statuses.
LTEnumDeclare(NSUInteger, INTSubscriptionStatus,
  INTSubscriptionStatusActive,
  INTSubscriptionStatusCancelled,
  INTSubscriptionStatusExpired
);

/// Represents a devices subscription info at some point in time.
@interface INTSubscriptionInfo : MTLModel

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the provided parameters.
- (instancetype)initWithSubscriptionStatus:(INTSubscriptionStatus *)subscriptionStatus
                                 productID:(NSString *)productID
                             transactionID:(NSString *)transactionID
                              purchaseDate:(NSDate *)purchaseDate
                            expirationDate:(NSDate *)expirationDate
                          cancellationDate:(nullable NSDate *)cancellationDate
    NS_DESIGNATED_INITIALIZER;

/// Status of the subscription.
@property (readonly, nonatomic) INTSubscriptionStatus *subscriptionStatus;

/// Subscription product id.
@property (readonly, nonatomic) NSString *productID;

/// Transaction id of the subscription purchase.
@property (readonly, nonatomic) NSString *transactionID;

/// The date the subscription was purchased.
@property (readonly, nonatomic) NSDate *purchaseDate;

/// Expiration date of the subscription.
@property (readonly, nonatomic) NSDate *expirationDate;

/// Cancellation date of the subscription. Available only if the subscription was canceled and not.
/// \c nil if the subscription had not beem canceled.
@property (readonly, nonatomic, nullable) NSDate *cancellationDate;

@end

NS_ASSUME_NONNULL_END
