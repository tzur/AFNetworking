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

  // TODO:(dlahyani) This is a patch for dealing with high prices for the soft-launch, that is only
  // released in the Russian AppStore. We should allow 2 fraction digits for most currencies though.
  [numberFormatter setMaximumFractionDigits:0];
  return [numberFormatter stringFromNumber:product.price];
}

@end

NS_ASSUME_NONNULL_END
