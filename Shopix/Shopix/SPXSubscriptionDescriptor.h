// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@class BZRBillingPeriod, BZRProductPriceInfo;

/// Descriptor representing a subscription product and providing information that is crucial for
/// presenting the product to the user.
@interface SPXSubscriptionDescriptor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c productIdentifier and \c discountPercentage set to \c 0.
- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier;

/// Initializes with \c productIdentifier that uniquely identify the product and
/// \c discountPercentage which defines a desired fictive discount percentage for the product. Must
/// be in range <tt>[0, 100)</tt>, otherwise a \c NSInvalidArgumentException is raised.
///
/// @see discountPercentage.
- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                       discountPercentage:(NSUInteger)discountPercentage
    NS_DESIGNATED_INITIALIZER;

/// The subscription unique identifier.
@property (readonly, nonatomic) NSString *productIdentifier;

/// Price information of the subscription product. KVO Compliant.
@property (strong, nonatomic, nullable) BZRProductPriceInfo *priceInfo;

/// Discount percentage in range <tt>[0, 100)</tt> defines a desired fictive discount percentage for
/// the product, where the price after the discount is \c priceInfo.price. \c 0 if there is no
/// discount.
///
/// The fictive full price can be calculated as following:
/// <tt>fullPrice = price * (100 / (100 - discountPercentage))</tt>.
/// For example, if \c priceInfo.price is \c 2.5 and \c discountPercentage is \c 50 so the
/// concluded fictive full price is \c 5.
@property (readonly, nonatomic) CGFloat discountPercentage;

/// Subscription's billing period. \c nil if the subscription is one-time payment.
@property (readonly, nonatomic, nullable) BZRBillingPeriod *billingPeriod;

@end

NS_ASSUME_NONNULL_END
