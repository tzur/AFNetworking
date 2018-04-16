// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRTimeConversion.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRTimeConversion

static const NSTimeInterval kNumberOfSecondsInDay = 24 * 60 * 60;

+ (NSTimeInterval)numberOfSecondsInDays:(NSUInteger)days {
  return ((NSTimeInterval)days) * kNumberOfSecondsInDay;
}

+ (NSUInteger)numberOfDaysInSeconds:(NSTimeInterval)seconds {
  return (NSUInteger)std::round(seconds / kNumberOfSecondsInDay);
}

@end

NS_ASSUME_NONNULL_END
