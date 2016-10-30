// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductPriceInfo.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRProductPriceInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRProductPriceInfo, price): @"price",
    @instanceKeypath(BZRProductPriceInfo, currencyCode): @"currencyCode",
    @instanceKeypath(BZRProductPriceInfo, localizedPrice): @"localizedPrice",
  };
}

@end

NS_ASSUME_NONNULL_END
