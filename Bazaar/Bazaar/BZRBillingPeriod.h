// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRBillingPeriodUnit
#pragma mark -

/// Possible billing period basic units for renewable-subscriptions.
LTEnumDeclare(NSUInteger, BZRBillingPeriodUnit,
  BZRBillingPeriodUnitDays,
  BZRBillingPeriodUnitWeeks,
  BZRBillingPeriodUnitMonths,
  BZRBillingPeriodUnitYears
);

#pragma mark -
#pragma mark BZRBillingPeriod
#pragma mark -

/// Billing period represented as a basic time unit and the number of times this basic unit fits in
/// a single billing period. For example a bi-yearly subscription will be represented as
/// billing period with <tt>unit=BZRBillingPeriodUnitMonths</tt> and <tt>unitCount=6</tt>.
@interface BZRBillingPeriod : BZRModel <MTLJSONSerializing>

/// Billing period basic unit.
@property (readonly, nonatomic) BZRBillingPeriodUnit *unit;

/// Number of units of the basic unit in the subscription period.
@property (readonly, nonatomic) NSUInteger unitCount;

@end

NS_ASSUME_NONNULL_END
