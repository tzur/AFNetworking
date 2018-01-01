// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRSubscriptionIntroductoryDiscount.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRSubscriptionIntroductoryDiscount (StoreKit)

/// Creates and initializes a new instance of \c BZRSubscriptionIntroductoryDiscount with
/// \c product.intorductoryPrice. If \c product.introductoryPrice is not available or \c nil this
/// method will return \c nil.
///
/// @note <tt>- [SKProduct introductoryPrice]</tt> is only available from iOS 11.2.
+ (nullable instancetype)introductoryDiscountForSKProduct:(SKProduct *)product;

/// Creates and initializes a new instance of \c BZRSubscriptionIntroductoryDiscount with
/// \c discount.
///
/// @note <tt>SKProductDiscount</tt> is only available from iOS 11.2 hence this method is only
/// available on iOS 11.2 or higher.
+ (instancetype)introductoryDiscountWithSKProductDiscount:(SKProductDiscount *)introductoryPrice
    NS_AVAILABLE_IOS(11.2);

@end

NS_ASSUME_NONNULL_END
