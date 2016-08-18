// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRTimeConversion.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRTimeConversion

+ (NSTimeInterval)numberOfSecondsInDays:(NSUInteger)days {
  static const NSTimeInterval kNumberOfSecondsInDay = 24 * 60 * 60;

  return ((NSTimeInterval)days) * kNumberOfSecondsInDay;
}

@end

NS_ASSUME_NONNULL_END
