// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import <LTKit/LTEnum.h>

NS_ASSUME_NONNULL_BEGIN

/// Different sources the subscription data can be taken from.
LTEnumDeclare(NSUInteger, BZRTweaksSubscriptionSource,
    BZRTweaksSubscriptionSourceOnDevice,
    BZRTweaksSubscriptionSourceGenericActive,
    BZRTweaksSubscriptionSourceNoSubscription,
    BZRTweaksSubscriptionSourceCustomizedSubscription
);

NS_ASSUME_NONNULL_END
