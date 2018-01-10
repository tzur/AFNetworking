// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@class BZRBillingPeriod, BZRProductPriceInfo;

/// Descriptor representing a subscription product and providing information that is crucial for
/// presenting the product to the user.
@interface SPXSubscriptionDescriptor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c productIdentifier that uniquely identify the product.
- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier;

/// The subscription unique identifier.
@property (readonly, nonatomic) NSString *productIdentifier;

/// Price information of the subscription product.
@property (strong, nonatomic, nullable) BZRProductPriceInfo *priceInfo;

/// Subscription's billing period. \c nil if the subscription is one-time payment.
@property (readonly, nonatomic, nullable) BZRBillingPeriod *billingPeriod;

@end

NS_ASSUME_NONNULL_END
