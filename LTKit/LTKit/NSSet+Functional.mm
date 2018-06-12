// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSSet+Functional.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSSet (Functional)

- (NSSet *)lt_map:(NS_NOESCAPE LTSetMapBlock)block {
  LTParameterAssert(block);

  auto mapped = [NSMutableSet setWithCapacity:self.count];
  for (id object in self) {
    [mapped addObject:block(object)];
  }
  return mapped;
}

- (instancetype)lt_filter:(NS_NOESCAPE LTSetFilterBlock)block {
  LTParameterAssert(block);

  return [self objectsPassingTest:^BOOL(id obj, BOOL *) {
    return block(obj);
  }];
}

@end

NS_ASSUME_NONNULL_END
