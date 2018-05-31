// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import <LTKit/LTEnum.h>

NS_ASSUME_NONNULL_BEGIN

/// Types of different sources the subscription data can be pulled from.
LTEnumDeclare(NSUInteger, BZRTweaksSubscriptionDataSourceType,
    BZRTweaksSubscriptionDataSourceTypeOnDevice,
    BZRTweaksSubscriptionDataSourceTypeGenericValid,
    BZRTweaksSubscriptionDataSourceTypeNoSubscription,
    BZRTweaksSubscriptionDataSourceTypeCustomizedSubscription
);

NS_ASSUME_NONNULL_END
