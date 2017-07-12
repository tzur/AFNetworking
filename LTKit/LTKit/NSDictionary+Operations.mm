// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSDictionary+Operations.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSDictionary (Operations)

- (instancetype)lt_merge:(NSDictionary *)dictionary {
  if (!dictionary.count) {
    return self;
  }

  NSMutableDictionary *newDictionary = [self mutableCopy];
  [newDictionary addEntriesFromDictionary:dictionary];

  return [newDictionary copy];
}

- (instancetype)lt_removeObjectsForKeys:(NSArray *)keys {
  NSMutableDictionary *newDictionary = [self mutableCopy];
  [newDictionary removeObjectsForKeys:keys];
  return [newDictionary copy];
}

@end

NS_ASSUME_NONNULL_END
