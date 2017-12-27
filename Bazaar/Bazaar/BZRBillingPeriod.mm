// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRBillingPeriod.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRBillingPeriodUnit
#pragma mark -

/// Possible billing period basic units for renewable-subscriptions.
LTEnumImplement(NSUInteger, BZRBillingPeriodUnit,
  BZRBillingPeriodUnitDays,
  BZRBillingPeriodUnitWeeks,
  BZRBillingPeriodUnitMonths,
  BZRBillingPeriodUnitYears
);

#pragma mark -
#pragma mark BZRBillingPeriod
#pragma mark -

@implementation BZRBillingPeriod

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRBillingPeriod, unit): @"unit",
    @instanceKeypath(BZRBillingPeriod, unitCount): @"unitCount"
  };
}

+ (NSValueTransformer *)unitJSONTransformer {
  return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
    @"days": $(BZRBillingPeriodUnitDays),
    @"weeks": $(BZRBillingPeriodUnitWeeks),
    @"months": $(BZRBillingPeriodUnitMonths),
    @"years": $(BZRBillingPeriodUnitYears)
  }];
}

@end

NS_ASSUME_NONNULL_END
