// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationStatusProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRTimeProvider;

/// Provider that provides the receipt validation status using an underlying provider and modifies
/// its subscription's expiry according to the given time provider and grace period.
@interface BZRModifiedExpiryReceiptValidationStatusProvider :
    NSObject <BZRReceiptValidationStatusProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c timeProvider, used to provide the current time, and with
/// \c expiredSubscriptionGracePeriod that specifies how many grace days the user is allowed to use
/// products that he acquired via subscription after its subscription has been expired.
- (instancetype)initWithTimeProvider:(BZRTimeProvider *)timeProvider
    expiredSubscriptionGracePeriod:(NSUInteger)expiredSubscriptionGracePeriod
    underlyingProvider:(id<BZRReceiptValidationStatusProvider>)underlyingProvider
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
