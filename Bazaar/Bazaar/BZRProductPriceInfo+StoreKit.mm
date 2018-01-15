// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductPriceInfo+StoreKit.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRProductPriceInfo (StoreKit)

+ (instancetype)productPriceInfoWithSKProduct:(SKProduct *)product {
  NSDictionary *dictionaryValue = @{
    @instanceKeypath(BZRProductPriceInfo, price): product.price,
    @instanceKeypath(BZRProductPriceInfo, localeIdentifier):
        [product.priceLocale objectForKey:NSLocaleIdentifier]
  };
  return lt::nn([BZRProductPriceInfo modelWithDictionary:dictionaryValue error:nil]);
}

@end

NS_ASSUME_NONNULL_END
