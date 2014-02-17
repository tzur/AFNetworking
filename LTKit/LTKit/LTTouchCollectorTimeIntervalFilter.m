// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTouchCollectorTimeIntervalFilter.h"

@interface LTTouchCollectorTimeIntervalFilter ()

@property (nonatomic) CFTimeInterval minimalTimeInterval;

@end

@implementation LTTouchCollectorTimeIntervalFilter

+ (instancetype)filterWithMinimalTimeInterval:(CFTimeInterval)interval {
  return [[LTTouchCollectorTimeIntervalFilter alloc] initWithMinimalTimeInterval:interval];
}

- (instancetype)initWithMinimalTimeInterval:(CFTimeInterval)interval {
  if (self = [super init]) {
    LTParameterAssert(interval >= 0);
    self.minimalTimeInterval = interval;
  }
  return self;
}

- (BOOL)acceptNewPoint:(LTPainterPoint *)newPoint withOldPoint:(LTPainterPoint *)oldPoint {
  return newPoint.timestamp - oldPoint.timestamp > self.minimalTimeInterval;
}

@end
