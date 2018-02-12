// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import <Bazaar/BZRBillingPeriod.h>

NS_ASSUME_NONNULL_BEGIN

@interface BZRBillingPeriod (Shopix)

/// Initializes with \c productIdentifier, the period billing is determined by the identifier's
/// period axis. \c nil is returned if there is no valid billing period.
+ (nullable instancetype)spx_billingPeriodWithProductIdentifier:(NSString *)productIdentifier;

/// Returns a localized string that represents the billing period unit. If \c monthlyFormat is
/// \c YES the period text will be in months - e.g 'Months' for yearly billing period, otherwise the
/// string will be the most native textual description of the billing period - e.g 'Year' for yearly
/// billing period.
- (NSString *)spx_billingPeriodString:(BOOL)monthlyFormat;

/// Retruns the number of months in the billing period. e.g \c 12 of yearly billing period. \c 0 is
/// returned if the billing period unit is smaller than month.
- (NSUInteger)spx_numberOfMonthsInPeriod;

@end

NS_ASSUME_NONNULL_END
