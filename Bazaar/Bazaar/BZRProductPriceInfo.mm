// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductPriceInfo.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRProductPriceInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRProductPriceInfo, price): @"price",
    @instanceKeypath(BZRProductPriceInfo, localeIdentifier): @"localeIdentifier",
    @instanceKeypath(BZRProductPriceInfo, fullPrice): @"fullPrice"
  };
}

+ (NSSet<NSString *> *)optionalPropertyKeys {
  static NSSet<NSString *> *optionalPropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    optionalPropertyKeys = [NSSet setWithObject:@instanceKeypath(BZRProductPriceInfo, fullPrice)];
  });

  return optionalPropertyKeys;
}

@end

NS_ASSUME_NONNULL_END
