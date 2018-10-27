// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Adds helper properties to \c BZRReceiptSubscriptionInfo.
@interface BZRReceiptSubscriptionInfo (HelperProperties)

/// The minimum between the expiration date time and the cancellation date. If cancellation data
/// does not exist, expiration date is returned.
@property (readonly, nonatomic) NSDate *effectiveExpirationDate;

/// \c YES if the subscription is not expired and the cancellation time is \c nil and \c NO
/// otherwise.
@property (readonly, nonatomic) BOOL isActive;

@end

NS_ASSUME_NONNULL_END
