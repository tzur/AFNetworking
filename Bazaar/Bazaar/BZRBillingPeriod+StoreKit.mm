// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRBillingPeriod+StoreKit.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRBillingPeriod (StoreKit)

+ (nullable instancetype)billingPeriodForSKProduct:(SKProduct *)product {
  if (@available(iOS 11.2, *)) {
    return product.subscriptionPeriod ?
        [self billingPeriodForSKProductSubscriptionPeriod:product.subscriptionPeriod] : nil;
  }

  return nil;
}

+ (instancetype)billingPeriodForSKProductSubscriptionPeriod:
   (SKProductSubscriptionPeriod *)subscriptionPeriod {
  static NSDictionary * const kSKProductPeriodUnitToBZRBillingPeriodUnit = @{
    @(SKProductPeriodUnitDay): $(BZRBillingPeriodUnitDays),
    @(SKProductPeriodUnitWeek): $(BZRBillingPeriodUnitWeeks),
    @(SKProductPeriodUnitMonth): $(BZRBillingPeriodUnitMonths),
    @(SKProductPeriodUnitYear): $(BZRBillingPeriodUnitYears)
  };

  return lt::nn([[self alloc] initWithDictionary:@{
    @instanceKeypath(BZRBillingPeriod, unit):
        kSKProductPeriodUnitToBZRBillingPeriodUnit[@(subscriptionPeriod.unit)],
    @instanceKeypath(BZRBillingPeriod, unitCount): @(subscriptionPeriod.numberOfUnits)
  } error:nil]);
}

@end

NS_ASSUME_NONNULL_END
