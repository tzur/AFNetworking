// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "NSDictionary+Merge.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSDictionary (Merge)

- (NSDictionary *)int_mergeUpdates:(NSDictionary *)updates {
  if (!updates.count) {
    return self;
  }

  NSSet *keysToRemove = [updates keysOfEntriesPassingTest:^BOOL(id, id object, BOOL *) {
    return [object isKindOfClass:NSNull.class];
  }];

  NSMutableDictionary *updatedDictionary = [self mutableCopy];

  [updatedDictionary addEntriesFromDictionary:updates];
  [updatedDictionary removeObjectsForKeys:[keysToRemove allObjects]];

  return [updatedDictionary copy];
}

- (NSDictionary *)int_dictionaryByAddingEntriesFromDictionary:(NSDictionary *)dictionary {
  if (!dictionary.count) {
    return self;
  }

  NSMutableDictionary *newDictionary = [self mutableCopy];
  [newDictionary addEntriesFromDictionary:dictionary];

  return [newDictionary copy];
}

@end

NS_ASSUME_NONNULL_END
