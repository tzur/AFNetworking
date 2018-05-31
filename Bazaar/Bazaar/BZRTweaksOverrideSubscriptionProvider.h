// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweaksSubscriptionDataSourceType.h"

@class BZRReceiptSubscriptionInfo;

NS_ASSUME_NONNULL_BEGIN

/// Used for overriding subscription info, provides data source signal and an override signal.
@protocol BZRTweaksOverrideSubscriptionProvider <NSObject>

/// The subscription created by the custom subscription tweaks, KVO compliant.
@property (readonly, nonatomic) BZRReceiptSubscriptionInfo *overridingSubscription;

/// Signal that sends a value whenever the subscription data source tweak is modified.
@property (readonly, nonatomic) RACSignal<BZRTweaksSubscriptionDataSourceType *>
    *subscriptionDataSource;

@end

NS_ASSUME_NONNULL_END
