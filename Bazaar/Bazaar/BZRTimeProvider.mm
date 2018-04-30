// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRTimeProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRTimeProvider

+ (BZRTimeProvider *)defaultTimeProvider {
  return [[BZRTimeProvider alloc] init];
}

- (RACSignal<NSDate *> *)currentTime {
  return [RACSignal defer:^{
    return [RACSignal return:[NSDate date]];
  }];
}

@end

NS_ASSUME_NONNULL_END
