// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRReceiptModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Adds convenience methods to create a generic subscription info.
@interface BZRReceiptSubscriptionInfo (GenericSubscription)

/// Creates a generic active subscription with pending renewal info.
+ (BZRReceiptSubscriptionInfo *)genericActiveSubscriptionWithPendingRenewalInfo;

@end

NS_ASSUME_NONNULL_END
