// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRBillingPeriod.h"

NS_ASSUME_NONNULL_BEGIN

/// Add convenience initializers for initializing a \c BZRBillingPeriod from \c SKProduct.
@interface BZRBillingPeriod (StoreKit)

/// Creates and initializes a new instance of \c BZRBillingPeriod with
/// \c product.subscriptionPeriod. If \c product.subscriptionPeriod is not available or \c nil this
/// method will return \c nil.
///
/// @note <tt>- [SKProduct subscriptionPeriod]</tt> is only available from iOS 11.2.
+ (nullable instancetype)billingPeriodForSKProduct:(SKProduct *)product;

/// Creates and initializes a new instance of \c BZRBillingPeriod with \c subscriptionPeriod.
///
/// @note <tt>SKProductSubscriptionPeriod</tt> is only available from iOS 11.2 hence this method is
/// only available on iOS 11.2 or higher.
+ (instancetype)billingPeriodForSKProductSubscriptionPeriod:
   (SKProductSubscriptionPeriod *)subscriptionPeriod NS_AVAILABLE_IOS(11.2);

@end

NS_ASSUME_NONNULL_END
