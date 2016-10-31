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
  return [numberFormatter stringFromNumber:product.price];
}

@end

NS_ASSUME_NONNULL_END
