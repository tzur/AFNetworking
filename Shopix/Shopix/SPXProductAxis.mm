// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SPXProductAxis.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SPXBaseProductAxisValue

@synthesize value = _value;

- (instancetype)initWithValue:(NSString *)value andAxis:(id<SPXBaseProductAxis>)axis {
  if (self = [super init]) {
    _axis = axis;
    _value = value;
  }
  return self;
}

+ (instancetype)axisValueWithValue:(NSString *)value andAxis:(id<SPXBaseProductAxis>)axis {
  return [[[self class] alloc] initWithValue:value andAxis:axis];
}

@end

@implementation SPXBenefitAxisValue

@synthesize value = _value;

- (instancetype)initWithValue:(NSString *)value andAxis:(id<SPXBenefitAxis>)axis {
  if (self = [super init]) {
    _axis = axis;
    _value = value;
  }
  return self;
}

+ (instancetype)axisValueWithValue:(NSString *)value andAxis:(id<SPXBenefitAxis>)axis {
  return [[[self class] alloc] initWithValue:value andAxis:axis];
}

@end

@implementation SPXBenefitProductAxisDiscountLevel

- (NSArray<id<SPXProductAxisValue>> *)values {
  return @[[self fullPrice], [self off10], [self off25], [self off50], [self off75]];
}

- (SPXBenefitAxisValue *)defaultValue {
  return [self fullPrice];
}

- (SPXBenefitAxisValue *)fullPrice {
  return [SPXBenefitAxisValue axisValueWithValue:@"FullPrice" andAxis:self];
}

- (SPXBenefitAxisValue *)off10 {
  return [SPXBenefitAxisValue axisValueWithValue:@"10Off" andAxis:self];
}

- (SPXBenefitAxisValue *)off25 {
  return [SPXBenefitAxisValue axisValueWithValue:@"25Off" andAxis:self];
}

- (SPXBenefitAxisValue *)off50 {
  return [SPXBenefitAxisValue axisValueWithValue:@"50Off" andAxis:self];
}

- (SPXBenefitAxisValue *)off75 {
  return [SPXBenefitAxisValue axisValueWithValue:@"75Off" andAxis:self];
}

@end

@implementation SPXBenefitProductAxisFreeTrialDuration

- (NSArray<id<SPXProductAxisValue>> *)values {
  return @[[self noTrial], [self threeDaysTrial], [self oneWeekTrial], [self oneMonthTrial],
           [self threeMonthsTrial], [self sixMonthsTrial]];
}

- (SPXBenefitAxisValue *)defaultValue {
  return [self noTrial];
}

- (SPXBenefitAxisValue *)noTrial {
  return [SPXBenefitAxisValue axisValueWithValue:@"NoTrial" andAxis:self];
}

- (SPXBenefitAxisValue *)threeDaysTrial {
  return [SPXBenefitAxisValue axisValueWithValue:@"3DaysTrial" andAxis:self];
}

- (SPXBenefitAxisValue *)oneWeekTrial {
  return [SPXBenefitAxisValue axisValueWithValue:@"1WeekTrial" andAxis:self];
}

- (SPXBenefitAxisValue *)oneMonthTrial {
  return [SPXBenefitAxisValue axisValueWithValue:@"1MonthTrial" andAxis:self];
}

- (SPXBenefitAxisValue *)threeMonthsTrial {
  return [SPXBenefitAxisValue axisValueWithValue:@"3MonthsTrial" andAxis:self];
}

- (SPXBenefitAxisValue *)sixMonthsTrial {
  return [SPXBenefitAxisValue axisValueWithValue:@"6MonthsTrial" andAxis:self];
}

@end

@implementation SPXBaseProductAxisSubscriptionPeriod

- (NSArray<id<SPXProductAxisValue>> *)values {
  return @[[self oneTimePayment], [self monthly], [self biYearly], [self yearly]];
}

- (SPXBaseProductAxisValue *)oneTimePayment {
  return [SPXBaseProductAxisValue axisValueWithValue:@"OneTimePayment" andAxis:self];
}

- (SPXBaseProductAxisValue *)monthly {
  return [SPXBaseProductAxisValue axisValueWithValue:@"Monthly" andAxis:self];
}

- (SPXBaseProductAxisValue *)biYearly {
  return [SPXBaseProductAxisValue axisValueWithValue:@"BiYearly" andAxis:self];
}

- (SPXBaseProductAxisValue *)yearly {
  return [SPXBaseProductAxisValue axisValueWithValue:@"Yearly" andAxis:self];
}

@end

@implementation SPXBaseProductAxis

+ (SPXBaseProductAxisSubscriptionPeriod *)subscriptionPeriod {
  return [[SPXBaseProductAxisSubscriptionPeriod alloc] init];
}

@end

@implementation SPXBenefitProductAxis

+ (SPXBenefitProductAxisDiscountLevel *)discountLevel {
  return [[SPXBenefitProductAxisDiscountLevel alloc] init];
}

+ (SPXBenefitProductAxisFreeTrialDuration *)freeTrialDuration {
  return [[SPXBenefitProductAxisFreeTrialDuration alloc] init];
}

@end

NS_ASSUME_NONNULL_END
