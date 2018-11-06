// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "RACStream+Photons.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RACStream (Photons)

- (__kindof RACStream *)ptn_identicallyDistinctUntilChanged {
  Class localSelfClass = self.class;

  return [[self bind:^RACStreamBindBlock(){
    __block id lastValue = nil;
    __block BOOL initial = YES;

    return ^(id x, BOOL __unused *stop) {
      if (!initial && (lastValue == x)) return [localSelfClass empty];

      initial = NO;
      lastValue = x;
      return [localSelfClass return:x];
    };
  }] setNameWithFormat:@"[%@] -ptn_identicallyDistinctUntilChanged", self.name];
}

@end

NS_ASSUME_NONNULL_END
