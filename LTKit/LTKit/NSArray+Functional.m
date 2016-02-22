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

@end

NS_ASSUME_NONNULL_END
