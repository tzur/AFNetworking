// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSDictionary+Functional.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSDictionary (Functional)

- (instancetype)lt_filter:(NS_NOESCAPE LTDictionaryFilterBlock)block {
  LTParameterAssert(block);

  NSMutableDictionary *filtered = [NSMutableDictionary dictionary];
  [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *) {
    if (block(key, obj)) {
      filtered[key] = obj;
    }
  }];
  return [filtered copy];
}

@end

NS_ASSUME_NONNULL_END
