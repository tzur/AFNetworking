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
  auto result = [self spx_decimalNumberByDividingBy:divisor roundingMode:NSRoundDown scale:2];
  return [[self spx_priceNumberFormatter:localeIdentifier] stringFromNumber:result];
}

- (NSDecimalNumber *)spx_decimalNumberByDividingBy:(NSUInteger)divisor
                                      roundingMode:(NSRoundingMode)roundingMode scale:(short)scale {
  auto decimalNumberHandler = [NSDecimalNumberHandler
                               decimalNumberHandlerWithRoundingMode:roundingMode scale:scale
                               raiseOnExactness:NO raiseOnOverflow:YES raiseOnUnderflow:YES
                               raiseOnDivideByZero:YES];
  auto decimalDivisor = [NSDecimalNumber decimalNumberWithDecimal:@(divisor).decimalValue];
  return [self decimalNumberByDividingBy:decimalDivisor withBehavior:decimalNumberHandler];
}

- (NSString *)spx_localizedFullPriceForLocale:(NSString *)localeIdentifier
                           discountPercentage:(NSUInteger)discountPercentage
                                    dividedBy:(NSUInteger)divisor {
  LTParameterAssert(discountPercentage < 100, @"Discount percentage must be smaller than 100, "
                    "got: %lu", (unsigned long)discountPercentage);

  static const auto kSmallPriceFraction = [[NSDecimalNumber alloc] initWithDouble:0.01];
  auto fullPrice = [[NSDecimalNumber alloc]
                    initWithDouble:self.floatValue * (100.0 / (100.0 - discountPercentage))];

  auto dividedFullPrice = [fullPrice spx_decimalNumberByDividingBy:divisor roundingMode:NSRoundUp
                                                             scale:0];
  // Decrease the price by a small fraction so it will end with '.99' if the number wasn't an
  // integer.
  if (std::floor(fullPrice.floatValue) != fullPrice.floatValue) {
    dividedFullPrice = [dividedFullPrice decimalNumberBySubtracting:kSmallPriceFraction];
  }
  return [[self spx_priceNumberFormatter:localeIdentifier] stringFromNumber:dividedFullPrice];
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
