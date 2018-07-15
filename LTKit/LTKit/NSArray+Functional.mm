// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSArray+Functional.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSArray (Functional)

- (NSArray *)lt_map:(NS_NOESCAPE LTArrayMapBlock)block {
  LTParameterAssert(block);

  NSMutableArray *mapped = [NSMutableArray arrayWithCapacity:self.count];
  for (id object in self) {
    [mapped addObject:block(object)];
  }
  return mapped;
}

- (NSArray *)lt_compactMap:(NS_NOESCAPE LTArrayCompactMapBlock)block {
  LTParameterAssert(block);

  NSMutableArray *mapped = [NSMutableArray array];
  for (id object in self) {
    id _Nullable mappedObject = block(object);
    if (mappedObject) {
      [mapped addObject:(id _Nonnull)mappedObject];
    }
  }
  return mapped;
}

- (id)lt_reduce:(NS_NOESCAPE LTArrayReduceBlock)block initial:(id)initialValue {
  LTParameterAssert(block);

  id currentValue = initialValue;
  for (id object in self) {
    currentValue = block(currentValue, object);
  }
  return currentValue;
}

- (NSArray *)lt_filter:(NS_NOESCAPE LTArrayFilterBlock)block {
  LTParameterAssert(block);

  NSPredicate *predicate =
      [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary<NSString *, id> *) {
        return block(object);
      }];
  return [self filteredArrayUsingPredicate:predicate];
}

- (nullable id)lt_find:(NS_NOESCAPE LTArrayFilterBlock)block {
  LTParameterAssert(block);

  NSUInteger index = [self indexOfObjectPassingTest:^BOOL(id object, NSUInteger, BOOL *) {
    return block(object);
  }];
  return index != NSNotFound ? [self objectAtIndex:index] : nil;
}

- (id _Nullable)lt_max:(NS_NOESCAPE LTArrayCompareBlock)areInIncreasingOrder {
  if (self.count == 0) {
    return nil;
  }

  id result = self.firstObject;
  for (id element in self) {
    if (areInIncreasingOrder(result, element)) {
      result = element;
    }
  }
  return result;
}

- (id _Nullable)lt_min:(NS_NOESCAPE LTArrayCompareBlock)areInIncreasingOrder {
  if (self.count == 0) {
    return nil;
  }

  id result = self.firstObject;
  for (id element in self) {
    if (areInIncreasingOrder(element, result)) {
      result = element;
    }
  }
  return result;
}

- (nullable id)lt_randomObject {
  return self.count ? self[arc4random_uniform((uint32_t)self.count)] : nil;
}

- (NSDictionary<id<NSCopying>, NSArray<id> *> *)
    lt_classify:(NS_NOESCAPE LTArrayClassifierBlock)block {
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
