// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "NSNumber+Localization.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSNumber (Localization)

- (NSString *)spx_localizedPriceForLocale:(NSString *)localeIdentifier {
  return [self spx_localizedPriceForLocale:localeIdentifier dividedBy:1];
}

- (NSString *)spx_localizedPriceForLocale:(NSString *)localeIdentifier
                                dividedBy:(NSUInteger)divisor {
  LTParameterAssert(divisor > 0, @"Price divisor must be greater than 0, got: %lu",
                    (unsigned long)divisor);

  auto numberFormatter = [self spx_priceNumberFormatter:localeIdentifier];
  return [numberFormatter stringFromNumber:@(floor(self.doubleValue / divisor * 100) / 100)];
}

- (NSNumberFormatter *)spx_priceNumberFormatter:(NSString *)localeIdentifier {
  auto numberFormatter = [[NSNumberFormatter alloc] init];
  [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
  [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
  [numberFormatter setLocale:[NSLocale localeWithLocaleIdentifier:localeIdentifier]];
  return numberFormatter;
}

@end

NS_ASSUME_NONNULL_END
