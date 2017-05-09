// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRDummyContentFetcherParameters.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRDummyContentFetcherParameters

- (instancetype)initWithValue:(NSString *)value {
  if (self = [super init]) {
    _value = [value copy];
  }
  return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRDummyContentFetcherParameters, value): @"value"
  };
}

@end

NS_ASSUME_NONNULL_END
