// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "RACStream+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RACStream (Photons)

- (instancetype)ptn_identicallyDistinctUntilChanged {
  Class class = self.class;

  return [[self bind:^{
    __block id lastValue = nil;
    __block BOOL initial = YES;

    return ^(id x, BOOL __unused *stop) {
      if (!initial && (lastValue == x)) return [class empty];

      initial = NO;
      lastValue = x;
      return [class return:x];
    };
  }] setNameWithFormat:@"[%@] -ptn_identicallyDistinctUntilChanged", self.name];
}

@end

NS_ASSUME_NONNULL_END
