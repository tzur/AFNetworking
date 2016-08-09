// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSArray+Functional.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSArray (Functional)

- (NSArray *)lt_map:(LTArrayMapBlock)block {
  LTParameterAssert(block);

  NSMutableArray *mapped = [NSMutableArray arrayWithCapacity:self.count];
  for (id object in self) {
    [mapped addObject:block(object)];
  }
  return mapped;
}

- (id)lt_reduce:(LTArrayReduceBlock)block initial:(id)initialValue {
  LTParameterAssert(block);

  id currentValue = initialValue;
  for (id object in self) {
    currentValue = block(currentValue, object);
  }
  return currentValue;
}

- (NSArray *)lt_filter:(LTArrayFilterBlock)block {
  LTParameterAssert(block);

  NSPredicate *predicate =
      [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary<NSString *, id> *) {
        return block(object);
      }];
  return [self filteredArrayUsingPredicate:predicate];
}

- (NSDictionary<id<NSCopying>, NSArray<id> *> *)lt_classify:(LTArrayClassifierBlock)block {
  LTParameterAssert(block);

  NSMutableDictionary<id<NSCopying>, NSMutableArray *> *classified =
      [NSMutableDictionary dictionary];
  for (id object in self) {
    id label = block(object);
    NSMutableArray *objectsMatchingLabel = classified[label] ?: [NSMutableArray array];
    [objectsMatchingLabel addObject:object];
    classified[label] = objectsMatchingLabel;
  }
  return [classified copy];
}

@end

NS_ASSUME_NONNULL_END
