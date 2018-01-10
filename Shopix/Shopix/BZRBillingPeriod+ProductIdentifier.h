// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import <Bazaar/BZRBillingPeriod.h>

NS_ASSUME_NONNULL_BEGIN

@interface BZRBillingPeriod (ProductIdentifier)

/// Initializes with \c productIdentifier, the period billing is determined by the identifier's
/// period axis. \c nil is returned if there is no valid billing period.
+ (nullable instancetype)spx_billingPeriodWithProductIdentifier:(NSString *)productIdentifier;

@end

NS_ASSUME_NONNULL_END
