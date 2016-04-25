// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSIndexSet+Blueprints.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSIndexSet (Blueprints)

+ (instancetype)blu_indexSetWithIndexes:(const std::set<NSUInteger> &)indexes {
  NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
  for (NSUInteger index : indexes) {
    [indexSet addIndex:index];
  }
  return [indexSet copy];
}

@end

NS_ASSUME_NONNULL_END
