// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainterStroke.h"

#import "LTCGExtensions.h"
#import "LTDegenerateInterpolationRoutine.h"
#import "LTInterpolationRoutine.h"
#import "LTLinearInterpolationRoutine.h"
#import "LTPainterStrokeSegment.h"
#import "LTPainterPoint.h"

@interface LTPainterStroke ()

/// Factory used to generate the interpolation routine for new segments of the stroke.
@property (strong, nonatomic) id<LTInterpolationRoutineFactory> factory;

/// Control points generating the stroke.
@property (strong, nonatomic) NSMutableArray *controlPoints;

/// Segments consisting the stroke, see the \c segments property.
@property (strong, nonatomic) NSMutableArray *mutableSegments;

@end

@implementation LTPainterStroke

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithInterpolationRoutineFactory:(id<LTInterpolationRoutineFactory>)factory
                                      startingPoint:(LTPainterPoint *)startingPoint {
  if (self = [super init]) {
    LTParameterAssert(factory);
    LTParameterAssert(startingPoint);
    self.factory = factory;
    self.controlPoints = [NSMutableArray arrayWithObject:startingPoint];
    self.mutableSegments = [NSMutableArray array];
  }
  return self;
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (LTPainterStrokeSegment *)addSegmentTo:(LTPainterPoint *)point {
  [self.controlPoints addObject:point];
  
  // Use the default factory, but fall back to a linear interpolation factory in case there aren't
  // enough control points.
  id<LTInterpolationRoutineFactory> factory = self.factory;
  if (self.controlPoints.count < factory.expectedKeyFrames - [factory rangeOfIntervalInWindow].location) {
    factory = [[LTLinearInterpolationRoutineFactory alloc] init];
  } else if (self.controlPoints.count < factory.expectedKeyFrames) {
    return nil;
  }
  
  NSUInteger neededPoints = factory.expectedKeyFrames;
  NSArray *keyPoints = [self.controlPoints subarrayWithRange:
                        NSMakeRange(self.controlPoints.count - neededPoints, neededPoints)];
  LTInterpolationRoutine *routine = [factory routineWithKeyFrames:keyPoints];
  NSArray *keyPointsOnInterval = [keyPoints subarrayWithRange:[factory rangeOfIntervalInWindow]];

  // The distance on the segment start is the distance of the first point on the segment interval,
  // unless we're dealing with a degenerate segment, meaning the point is disconnected so its
  // distance should be manually calculated.
  CGFloat distanceOnSegmentStart = [keyPointsOnInterval.firstObject distanceFromStart];
  if ([routine isKindOfClass:[LTDegenerateInterpolationRoutine class]]) {
    distanceOnSegmentStart +=
        CGPointDistance(point.contentPosition,
                        [self.controlPoints[self.controlPoints.count - 2] contentPosition]);
  }
  LTPainterStrokeSegment *segment =
      [[LTPainterStrokeSegment alloc] initWithSegmentIndex:self.mutableSegments.count
                                                 zoomScale:[keyPoints.firstObject zoomScale]
                                         distanceFromStart:distanceOnSegmentStart
                                   andInterpolationRoutine:routine];

  [keyPointsOnInterval.lastObject setDistanceFromStart:distanceOnSegmentStart + segment.length];
  [self.mutableSegments addObject:segment];
  return segment;
}

- (void)addPointAt:(LTPainterPoint *)point {
  LTPainterPoint *lastPoint = self.controlPoints.lastObject;
  point.distanceFromStart = lastPoint.distanceFromStart +
                            CGPointDistance(lastPoint.contentPosition, point.contentPosition);
  [self.controlPoints addObject:point];
  [self.mutableSegments addObject:point];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (LTPainterPoint *)startingPoint {
  return self.controlPoints.firstObject;
}

- (NSArray *)segments {
  return self.mutableSegments;
}

@end
