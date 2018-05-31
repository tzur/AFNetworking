// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweaksSubscriptionSource.h"

@class BZRReceiptSubscriptionInfo;

NS_ASSUME_NONNULL_BEGIN

/// Used for overriding subscription info, provides subscription source signal and an overriding
/// subscription.
@protocol BZRTweaksOverrideSubscriptionProvider <NSObject>

/// The subscription created by the custom subscription tweaks, KVO compliant.
@property (readonly, nonatomic, nullable) BZRReceiptSubscriptionInfo *overridingSubscription;

/// Signal that sends a value whenever the subscription source tweak is modified.
@property (readonly, nonatomic) RACSignal<BZRTweaksSubscriptionSource *> *subscriptionSourceSignal;

@end

NS_ASSUME_NONNULL_END
