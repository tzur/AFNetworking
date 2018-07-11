// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRBillingPeriod+Shopix.h"

NS_ASSUME_NONNULL_BEGIN

using namespace spx;

@implementation BZRBillingPeriod (Shopix)

+ (nullable instancetype)spx_billingPeriodWithProductIdentifier:(NSString *)productIdentifier {
  auto _Nullable dictionary = [BZRBillingPeriod spx_periodOfProductIdentifier:productIdentifier];
  return dictionary ? [[BZRBillingPeriod alloc] initWithDictionary:dictionary error:nil] : nil;
}

+ (nullable NSDictionary *)spx_periodOfProductIdentifier:(NSString *)productIdentifier {
  static const NSUInteger kNewFormatProductSpecifierIndex = 2;

  NSString *productSpecifierComponent;
  if ([self spx_isNewFormat:productIdentifier]) {
    if ([productIdentifier componentsSeparatedByString:@"_"].count < 3) {
      LogWarning(@"Received product ID with unrecognized format: %@", productIdentifier);
      return nil;
    }

    productSpecifierComponent =
        [productIdentifier componentsSeparatedByString:@"_"][kNewFormatProductSpecifierIndex];
  } else {
    productSpecifierComponent = productIdentifier;
  }

  auto productSpecificProperties = [productSpecifierComponent componentsSeparatedByString:@"."];
  for (NSString *component in productSpecificProperties) {
    if ([component isEqualToString:@"Monthly"] || [component isEqualToString:@"1M"]) {
      return @{
        @"unit": $(BZRBillingPeriodUnitMonths),
        @"unitCount": @1
      };
    } else if ([component isEqualToString:@"BiYearly"] || [component isEqualToString:@"6M"]) {
      return @{
        @"unit": $(BZRBillingPeriodUnitMonths),
        @"unitCount": @6
      };
    } else if ([component isEqualToString:@"Yearly"] || [component isEqualToString:@"1Y"]) {
      return @{
        @"unit": $(BZRBillingPeriodUnitYears),
        @"unitCount": @1
      };
    }
  }

  return nil;
}

+ (BOOL)spx_isNewFormat:(NSString *)productIdentifier {
  return [productIdentifier containsString:@"_"];
}

- (NSString *)spx_billingPeriodString:(BOOL)monthlyFormat {
  switch (self.unit.value) {
    case BZRBillingPeriodUnitYears:
      return monthlyFormat ?
          [self spx_billingPeriodStringForMonths:self.unitCount * 12] :
          [self spx_billingPeriodStringForYears:(self.unitCount)];
    case BZRBillingPeriodUnitMonths:
      return [self spx_billingPeriodStringForMonths:self.unitCount];
    case BZRBillingPeriodUnitWeeks:
      return [self spx_billingPeriodStringForWeeks:self.unitCount];
    case BZRBillingPeriodUnitDays:
      return [self spx_billingPeriodStringForDays:self.unitCount];
  }
}

- (NSString *)spx_billingPeriodStringForYears:(NSUInteger)numberOfYears {
  auto year = _LDefault(@"Year", @"Label on a button for purchasing subscription that renews every "
                        "one year");
  auto years = _LDefault(@"Years", @"Label on a button for purchasing subscription that renews "
                         "every x years");
  return numberOfYears > 1 ? years : year;
}

- (NSString *)spx_billingPeriodStringForMonths:(NSUInteger)numberOfMonths {
  auto month = _LDefault(@"Month", @"Label on a button for purchasing subscription that renews "
                         "every one month");
  auto months = _LDefault(@"Months", @"Label on a button for purchasing subscription that renews "
                          "every x months");
  return numberOfMonths > 1 ? months : month;
}

- (NSString *)spx_billingPeriodStringForWeeks:(NSUInteger)numberOfWeeks {
  auto week = _LDefault(@"Week", @"Label on a button for purchasing subscription that renews every "
                        "one week");
  auto weeks = _LDefault(@"Weeks", @"Label on a button for purchasing subscription that renews "
                         "every x weeks");
  return numberOfWeeks > 1 ? weeks : week;
}

- (NSString *)spx_billingPeriodStringForDays:(NSUInteger)numberOfDays {
  auto day = _LDefault(@"Day", @"Label on a button for purchasing subscription that renews every "
                       "one day");
  auto days = _LDefault(@"Days", @"Label on a button for purchasing subscription that renews "
                        "every x days");
  return numberOfDays > 1 ? days : day;
}

- (NSUInteger)spx_numberOfMonthsInPeriod {
  switch (self.unit.value) {
    case BZRBillingPeriodUnitYears:
      return self.unitCount * 12;
    case BZRBillingPeriodUnitMonths:
      return self.unitCount;
    default:
      return 0;
  }
}

@end

NS_ASSUME_NONNULL_END
