// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRTimeProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRTimeProvider

- (RACSignal *)currentTime {
  return [RACSignal defer:^RACSignal *{
   return [RACSignal return:[NSDate date]];
  }];
}

@end

NS_ASSUME_NONNULL_END
