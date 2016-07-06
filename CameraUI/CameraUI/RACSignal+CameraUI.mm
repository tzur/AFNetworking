// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "RACSignal+CameraUI.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RACSignal (CameraUI)

- (RACSignal *)cui_unpackFirst {
  return [[self cui_unpack:0] setNameWithFormat:@"[%@] -cui_unpackFirst", self.name];
}

- (RACSignal *)cui_unpack:(NSUInteger)index {
  @weakify(self);
  return [[self map:^id(RACTuple *tuple) {
    @strongify(self);
    LTParameterAssert([tuple isKindOfClass:RACTuple.class],
        @"Value from signal %@ is not a tuple: %@", self, tuple);
    LTParameterAssert(index < tuple.count,
        @"Tuple %@ in signal %@ doesn't contain index %lu", tuple, self, (unsigned long)index);
    return tuple[index];
  }] setNameWithFormat:@"[%@] -cui_unpack:%lu", self.name, (unsigned long)index];
}

@end

NS_ASSUME_NONNULL_END
