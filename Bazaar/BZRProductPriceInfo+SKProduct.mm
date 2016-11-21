// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductPriceInfo+SKProduct.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRProductPriceInfo (SKProduct)

+ (instancetype)productPriceInfoWithSKProduct:(SKProduct *)product {
  NSDictionary *dictionaryValue = @{
    @instanceKeypath(BZRProductPriceInfo, price): product.price,
    @instanceKeypath(BZRProductPriceInfo, currencyCode):
        [product.priceLocale objectForKey:NSLocaleCurrencyCode],
    @instanceKeypath(BZRProductPriceInfo, localizedPrice):
        [BZRProductPriceInfo localizedPrice:product]
  };
  return [BZRProductPriceInfo modelWithDictionary:dictionaryValue error:nil];
}

+ (NSString *)localizedPrice:(SKProduct *)product {
  NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
  [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
  [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
  [numberFormatter setLocale:product.priceLocale];

  // Truncate fraction digit in case the price is the price is an integer number to avoid prices
  // like "500.00 RUB" for which the ".00" is redundant and may cause price labels text overflow.
  if (std::floor([product.price doubleValue]) == [product.price doubleValue]) {
    [numberFormatter setMaximumFractionDigits:0];
  }
  return [numberFormatter stringFromNumber:product.price];
}

@end

NS_ASSUME_NONNULL_END
