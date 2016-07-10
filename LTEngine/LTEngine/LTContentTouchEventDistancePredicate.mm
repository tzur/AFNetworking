// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventDistancePredicate.h"

#import "LTContentTouchEvent.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTContentTouchEventDistancePredicate

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithType:(LTContentTouchEventDistancePredicateType)type
             minimumDistance:(CGFloat)distance {
  LTParameterAssert(distance >= 0, @"Invalid minimum distance (%g): must be nonnegative", distance);

  if (self = [super init]) {
    _type = type;
    _minimumDistance = distance;
  }
  return self;
}

+ (instancetype)predicateWithMinimumViewDistance:(CGFloat)distance {
  return [[[self class] alloc]
          initWithType:LTContentTouchEventDistancePredicateTypeView minimumDistance:distance];
}

+ (instancetype)predicateWithMinimumContentDistance:(CGFloat)distance {
  return [[[self class] alloc]
          initWithType:LTContentTouchEventDistancePredicateTypeContent minimumDistance:distance];
}

#pragma mark -
#pragma mark LTContentTouchEventPredicate
#pragma mark -

- (BOOL)isValidEvent:(id<LTContentTouchEvent>)event givenEvent:(id<LTContentTouchEvent>)baseEvent {
  return CGPointDistance([self locationOfEvent:event],
                         [self locationOfEvent:baseEvent]) > self.minimumDistance;
}

- (CGPoint)locationOfEvent:(id<LTContentTouchEvent>)event {
  return self.type == LTContentTouchEventDistancePredicateTypeView ?
      event.viewLocation : event.contentLocation;
}

@end

NS_ASSUME_NONNULL_END
