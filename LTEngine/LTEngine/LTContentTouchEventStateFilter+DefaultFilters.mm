// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventStateFilter+DefaultFilters.h"

#import "LTContentTouchEventDistancePredicate.h"
#import "LTContentTouchEventOrPredicate.h"
#import "LTContentTouchEventTimeIntervalPredicate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTContentTouchEventStateFilter (DefaultFilters)

#pragma mark -
#pragma mark Factory Methods
#pragma mark -

const CGFloat kMinimumViewDistanceForPossibleState = 15;
const NSTimeInterval kMinimumTimeIntervalForPossibleState = 0.3;
const CGFloat kMinimumViewDistanceForActiveState = 5;
const NSTimeInterval kMinimumTimeIntervalForActiveState = 0.3;

+ (instancetype)touchFilterRejectingStationaryTouches {
  id<LTContentTouchEventPredicate> predicateForPossibleState =
      [LTContentTouchEventDistancePredicate
       predicateWithMinimumViewDistance:kMinimumViewDistanceForPossibleState];
  id<LTContentTouchEventPredicate> predicateForActiveState =
      [LTContentTouchEventDistancePredicate
       predicateWithMinimumViewDistance:kMinimumViewDistanceForActiveState];

  return [[[self class] alloc] initWithPredicateForPossibleState:predicateForPossibleState
                                         predicateForActiveState:predicateForActiveState];
}

+ (instancetype)touchFilterAcceptingStationaryTouches {
  id<LTContentTouchEventPredicate> predicateForPossibleState =
      [LTContentTouchEventOrPredicate predicateWithPredicates:@[
        [LTContentTouchEventTimeIntervalPredicate
         predicateWithMinimumTimeInterval:kMinimumTimeIntervalForPossibleState],
        [LTContentTouchEventDistancePredicate
         predicateWithMinimumViewDistance:kMinimumViewDistanceForPossibleState]
    ]];

  id<LTContentTouchEventPredicate> predicateForActiveState =
      [LTContentTouchEventOrPredicate predicateWithPredicates:@[
        [LTContentTouchEventTimeIntervalPredicate
         predicateWithMinimumTimeInterval:kMinimumTimeIntervalForActiveState],
        [LTContentTouchEventDistancePredicate
         predicateWithMinimumViewDistance:kMinimumViewDistanceForActiveState]
    ]];

  return [[[self class] alloc] initWithPredicateForPossibleState:predicateForPossibleState
                                         predicateForActiveState:predicateForActiveState];
}

@end

NS_ASSUME_NONNULL_END
