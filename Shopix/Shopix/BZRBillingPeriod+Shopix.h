// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import <Bazaar/BZRBillingPeriod.h>

NS_ASSUME_NONNULL_BEGIN

@interface BZRBillingPeriod (Shopix)

/// Initializes with \c productIdentifier, the period billing is determined by the identifier's
/// period axis. \c nil is returned if there is no valid billing period.
///
/// @note The format of the product identifier is expected to be one of the following:
/// - No underscore delimiter. Example: com.lightricks.foo.V1.FullPrice.NoTrial.Yearly.
/// - With underscore delimiter. Examples: com.lightricks.foo_V1.PA.1M.SA_1Y.SA,
/// com.lightricks.foo_V1.PA.1M.SA_1Y.SA_TRIAL.3D.
+ (nullable instancetype)spx_billingPeriodWithProductIdentifier:(NSString *)productIdentifier;

/// Returns a localized string that represents the billing period unit. If \c monthlyFormat is
/// \c YES the period text will be in months - e.g 'Months' for yearly billing period, otherwise the
/// string will be the most native textual description of the billing period - e.g 'Year' for yearly
/// billing period.
- (NSString *)spx_billingPeriodString:(BOOL)monthlyFormat;

/// Returns the number of months in the billing period. e.g \c 12 for yearly billing period. \c 0 is
/// returned if the billing period unit is shorter than a month.
- (NSUInteger)spx_numberOfMonthsInPeriod;

@end

NS_ASSUME_NONNULL_END
