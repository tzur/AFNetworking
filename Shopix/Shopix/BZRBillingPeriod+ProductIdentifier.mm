// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRBillingPeriod+ProductIdentifier.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRBillingPeriod (ProductIdentifier)

+ (nullable instancetype)spx_billingPeriodWithProductIdentifier:(NSString *)productIdentifier {
  return [[BZRBillingPeriod alloc] initWithDictionary:
          [BZRBillingPeriod periodOfProductIdentifier:productIdentifier] error:nil];
}

+ (NSDictionary *)periodOfProductIdentifier:(NSString *)productIdentifier {
  auto productIdentifierComponents = [productIdentifier componentsSeparatedByString:@"."];
  for (NSString *component in [productIdentifierComponents reverseObjectEnumerator]) {
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

@end

NS_ASSUME_NONNULL_END
