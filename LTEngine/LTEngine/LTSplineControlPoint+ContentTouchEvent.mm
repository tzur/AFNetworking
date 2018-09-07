// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSplineControlPoint+ContentTouchEvent.h"

#import "LTSplineControlPoint+AttributeKeys.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTSplineControlPoint (ContentTouchEvent)

#pragma mark -
#pragma mark Public Interface
#pragma mark -

+ (NSArray<LTSplineControlPoint *> *)pointsFromTouchEvents:(LTContentTouchEvents *)events {
  NSMutableArray<LTSplineControlPoint *> *mutablePoints =
      [NSMutableArray arrayWithCapacity:events.count];

  for (id<LTContentTouchEvent> event in events) {
    [mutablePoints addObject:[self pointFromContentTouchEvent:event]];
  }

  return [mutablePoints copy];
}

+ (LTSplineControlPoint *)pointFromContentTouchEvent:(id<LTContentTouchEvent>)event {
  return [[LTSplineControlPoint alloc]
          initWithTimestamp:event.timestamp location:event.contentLocation
          attributes:[self attributesFromContentTouchEvent:event]];
}

+ (NSDictionary<NSString *, NSNumber *> *)
    attributesFromContentTouchEvent:(id<LTContentTouchEvent>)event {
  NSDictionary<NSString *, NSNumber *> *attributes =
      [@{[self keyForRadius]: @(event.majorContentRadius)} mutableCopy];
  if (event.force) {
    [attributes setValue:event.force forKey:[self keyForForce]];
  }
  [attributes setValue:event.speedInViewCoordinates ?: @0
                forKey:[self keyForSpeedInScreenCoordinates]];
  return attributes;
}

@end

NS_ASSUME_NONNULL_END
