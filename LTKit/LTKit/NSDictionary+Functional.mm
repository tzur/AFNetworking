// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSDictionary+Functional.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSDictionary (Functional)

- (NSDictionary *)lt_mapValues:(NS_NOESCAPE LTDictionaryMapBlock)block {
  LTParameterAssert(block);

  auto mapped = [NSMutableDictionary dictionaryWithCapacity:self.count];
  [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *) {
    id _Nullable newObj = block(key, obj);
    LTParameterAssert(newObj, @"Return value of dictionary map for key %@ and value %@ block must "
                      "not be nil", key, obj);
    mapped[key] = newObj;
  }];
  return [mapped copy];
}

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

- (NSArray *)lt_mapToArray:(NS_NOESCAPE LTDictionaryMapBlock)block {
  LTParameterAssert(block);

  auto mapped = [NSMutableArray arrayWithCapacity:self.count];
  [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *) {
    [mapped addObject:block(key, obj)];
  }];
  return [mapped copy];
}

@end

NS_ASSUME_NONNULL_END
