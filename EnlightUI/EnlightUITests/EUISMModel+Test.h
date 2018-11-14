// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRBillingPeriod;

/// Category to ease the testing of EnlightUI subscription management components.
@interface EUISMModel (Test)

/// Creates and returns an EUISMModel with the given \c application as the current application, and
/// \c EUISMSubscriptionTypeSingleApp as the subscription type.
+ (instancetype)modelWithSingleAppSubscriptionForApplication:(EUISMApplication *)application;

/// Creates and returns an EUISMModel with \c EUISMSubscriptionTypeEcoSystem as the subscription
/// type.
+ (instancetype)modelWithEcoSystemSubscription;

/// Creates and returns an EUISMModel with current subscription in billing retry period if given
/// \c billingIssues is \c YES, and not in billing retry period if \c billingIssues is \c NO.
+ (instancetype)modelWithBillingIssues:(BOOL)billingIssues;

/// Creates and returns an EUISMModel with current product with the given \c billingPeriod. If
/// given \c expired is \c YES, the current subscription is expired, else it is not expired.
+ (instancetype)modelWithBillingPeriod:(BZRBillingPeriod *)billingPeriod expired:(BOOL)expired;

/// Creates and returns an EUISMModel with current product with the given \c productID.
+ (instancetype)modelWithCurrentProductID:(NSString *)productID;

/// Creates and returns an EUISMModel with pending product (the product that will be current after
/// subscription renews) with the given \c pendingProductID.
+ (instancetype)modelWithPendingProductID:(NSString *)pendingProductID;

/// Creates and returns an EUISMModel with \c nil as current subscription.
+ (instancetype)modelWithNoSubscription;

/// Creates and returns an EUISMModel that its current subscription is with auto renewal if the
/// given \c autoRenewal is \c YES and without auto renewal otherwise.
+ (instancetype)modelWithAutoRenewal:(BOOL)autoRenewal;

/// Creates and returns an EUISMModel that its current subscription expires at the given
/// \c expirationTime.
+ (instancetype)modelWithExpirationTime:(NSDate *)expirationTime;

@end

NS_ASSUME_NONNULL_END
