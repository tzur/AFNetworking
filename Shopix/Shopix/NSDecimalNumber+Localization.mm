// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "NSDecimalNumber+Localization.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSDecimalNumber (Localization)

- (NSString *)spx_localizedPriceForLocale:(NSString *)localeIdentifier {
  return [self spx_localizedPriceForLocale:localeIdentifier dividedBy:1];
}

- (NSString *)spx_localizedPriceForLocale:(NSString *)localeIdentifier
                                dividedBy:(NSUInteger)divisor {
  auto decimalNumberHandler = [NSDecimalNumberHandler
                               decimalNumberHandlerWithRoundingMode:NSRoundDown scale:2
                               raiseOnExactness:NO raiseOnOverflow:YES raiseOnUnderflow:YES
                               raiseOnDivideByZero:YES];
  auto decimalDivisor = [NSDecimalNumber decimalNumberWithDecimal:@(divisor).decimalValue];
  auto result = [self decimalNumberByDividingBy:decimalDivisor withBehavior:decimalNumberHandler];

  return [[self spx_priceNumberFormatter:localeIdentifier] stringFromNumber:result];
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
