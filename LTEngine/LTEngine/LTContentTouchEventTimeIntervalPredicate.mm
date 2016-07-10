// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventTimeIntervalPredicate.h"

#import "LTContentTouchEvent.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTContentTouchEventTimeIntervalPredicate

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithMinimumTimeInterval:(NSTimeInterval)interval {
  LTParameterAssert(interval >= 0, @"Invalid minimum interval (%g): must be nonnegative", interval);

  if (self = [super init]) {
    _minimumInterval = interval;
  }
  return self;
}

+ (instancetype)predicateWithMinimumTimeInterval:(NSTimeInterval)interval {
  return [[[self class] alloc] initWithMinimumTimeInterval:interval];
}

#pragma mark -
#pragma mark LTContentTouchEventPredicate
#pragma mark -

- (BOOL)isValidEvent:(id<LTContentTouchEvent>)event givenEvent:(id<LTContentTouchEvent>)baseEvent {
  return (event.timestamp - baseEvent.timestamp) > self.minimumInterval;
}

@end

NS_ASSUME_NONNULL_END
