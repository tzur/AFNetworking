// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTouchCollectorDistanceFilter.h"

#import "LTCGExtensions.h"

@interface LTTouchCollectorDistanceFilter ()

/// Distance metric type.
@property (nonatomic) LTTouchCollectorDistanceType type;
/// Distance threshold for accepting new points. Points will be accepted if their distance is
/// greater than this threshold.
@property (nonatomic) CGFloat minimalDistance;

@end

@implementation LTTouchCollectorDistanceFilter

#pragma mark -
#pragma mark Class Methods
#pragma mark -

+ (instancetype)filterWithMinimalScreenDistance:(CGFloat)distance {
  return [[LTTouchCollectorDistanceFilter alloc] initWithType:LTTouchCollectorScreenDistance
                                              minimalDistance:distance];
}

+ (instancetype)filterWithMinimalContentDistance:(CGFloat)distance {
  return [[LTTouchCollectorDistanceFilter alloc] initWithType:LTTouchCollectorContentDistance
                                              minimalDistance:distance];
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithType:(LTTouchCollectorDistanceType)type minimalDistance:(CGFloat)distance {
  if (self = [super init]) {
    LTParameterAssert(distance >= 0);
    self.type = type;
    self.minimalDistance = distance;
  }
  return self;
}

- (BOOL)acceptNewPoint:(LTPainterPoint *)newPoint withOldPoint:(LTPainterPoint *)oldPoint {
  return CGPointDistance([self positionForPoint:oldPoint],
                         [self positionForPoint:newPoint]) > self.minimalDistance;
}

- (CGPoint)positionForPoint:(LTPainterPoint *)point {
  return (self.type == LTTouchCollectorScreenDistance) ?
      point.screenPosition : point.contentPosition;
}

@end
