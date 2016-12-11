// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductPriceInfo+SKProduct.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRProductPriceInfo (SKProduct)

+ (instancetype)productPriceInfoWithSKProduct:(SKProduct *)product {
  NSDictionary *dictionaryValue = @{
    @instanceKeypath(BZRProductPriceInfo, price): product.price,
    @instanceKeypath(BZRProductPriceInfo, localeIdentifier):
        [product.priceLocale objectForKey:NSLocaleIdentifier]
  };
  return [BZRProductPriceInfo modelWithDictionary:dictionaryValue error:nil];
}

@end

NS_ASSUME_NONNULL_END
