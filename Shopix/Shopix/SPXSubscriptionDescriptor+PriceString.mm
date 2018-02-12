// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionDescriptor+PriceString.h"

#import <Bazaar/BZRBillingPeriod.h>
#import <Bazaar/BZRProductPriceInfo.h>

#import "NSDecimalNumber+Localization.h"

NS_ASSUME_NONNULL_BEGIN

using namespace spx;

@implementation SPXSubscriptionDescriptor (PriceString)

- (nullable NSString *)priceString:(BOOL)monthlyFormat {
  if (!self.priceInfo) {
    LogError(@"Price string for subscription product (%@) is requested but price information is "
             "nil", self.productIdentifier);
    return nil;
  }

  return [self.priceInfo.price
          spx_localizedPriceForLocale:self.priceInfo.localeIdentifier
          dividedBy:[self divisorForBillingPeriod:monthlyFormat]];
}

- (NSUInteger)divisorForBillingPeriod:(BOOL)monthlyFormat {
  // If there is no billing period, the subscription is a one-time-payment.
  return (monthlyFormat && self.billingPeriod) ?
      [self numberOfMonthsInSubscriptionPeriod:self.billingPeriod] : 1;
}

- (NSUInteger)numberOfMonthsInSubscriptionPeriod:(BZRBillingPeriod *)billingPeriod {
  if ([billingPeriod.unit isEqual:$(BZRBillingPeriodUnitMonths)]) {
    return billingPeriod.unitCount;
  } else if ([billingPeriod.unit isEqual:$(BZRBillingPeriodUnitYears)]) {
    return billingPeriod.unitCount * 12;
  }

  LTParameterAssert(NO, @"Unsupported monthly format for billing period: %@)", billingPeriod);
}

- (nullable NSString *)fullPriceString:(BOOL)monthlyFormat {
  if (!self.priceInfo) {
    LogError(@"Full price string for subscription product (%@) is requested but the price "
             "information is nil", self.productIdentifier);
    return nil;
  }

  NSUInteger divisor = [self divisorForBillingPeriod:monthlyFormat];
  if (self.priceInfo.fullPrice) {
    return [self.priceInfo.fullPrice
            spx_localizedPriceForLocale:self.priceInfo.localeIdentifier
            dividedBy:divisor];
  } else if (self.discountPercentage) {
    return [self.priceInfo.price
            spx_localizedFullPriceForLocale:self.priceInfo.localeIdentifier
            discountPercentage:self.discountPercentage dividedBy:divisor];
  }

  return nil;
}

@end

NS_ASSUME_NONNULL_END
