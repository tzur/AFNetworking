// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainterStrokeSegment.h"

#import "LTCGExtensions.h"
#import "LTInterpolationRoutine.h"
#import "LTPainterPoint.h"

@interface LTPainterStrokeSegment ()

@property (nonatomic) NSUInteger index;
@property (nonatomic) CGFloat distanceFromStart;
@property (nonatomic) CGFloat length;
@property (nonatomic) CGFloat zoomScale;

/// Starting point of the segment.
@property (strong, nonatomic) LTPainterPoint *startPoint;

/// Ending point of the segment.
@property (strong, nonatomic) LTPainterPoint *endPoint;

/// Interpolation routine used for generating points along the segment.
@property (strong, nonatomic) LTInterpolationRoutine *routine;

/// Array of distances of each sampling point along the segment.
@property (strong, nonatomic) NSArray *distances;

@end

@implementation LTPainterStrokeSegment

/// Number of sample points used for approximating the length of the segment.
static const NSUInteger kNumSamplesForLengthEstimation = 500;

- (instancetype)initWithSegmentIndex:(NSUInteger)index
                           zoomScale:(CGFloat)zoomScale
                   distanceFromStart:(CGFloat)distance
             andInterpolationRoutine:(LTInterpolationRoutine *)routine {
  if (self = [super init]) {
    LTParameterAssert(routine);
    LTParameterAssert(zoomScale > 0);
    LTParameterAssert(distance >= 0);
    self.index = index;
    self.zoomScale = zoomScale;
    self.distanceFromStart = distance;
    self.routine = routine;
    self.startPoint = [routine valueAtKey:0];
    self.endPoint = [routine valueAtKey:1];
    self.distances = [self esimtateLengthWithNumberOfSamples:kNumSamplesForLengthEstimation];
    self.length = [self.distances.lastObject doubleValue];
  }
  return self;
}

- (NSArray *)esimtateLengthWithNumberOfSamples:(NSUInteger)count {
  LTParameterAssert(count > 1);
  CGFloat length = 0;
  CGFloat step = 1.0 / count;
  CGPoint previousPoint = self.startPoint.contentPosition;
  NSMutableArray *distances = [NSMutableArray arrayWithObject:@(0)];
  for (NSUInteger i = 1; i < count; ++i) {
    CGFloat x = [[self.routine valueOfPropertyNamed:@"contentPositionX" atKey:i*step] doubleValue];
    CGFloat y = [[self.routine valueOfPropertyNamed:@"contentPositionY" atKey:i*step] doubleValue];
    CGPoint point = CGPointMake(x, y);
    length += CGPointDistance(previousPoint, point);
    [distances addObject:@(length)];
    previousPoint = point;
  }
  return distances;
}

- (NSArray *)pointsWithInterval:(CGFloat)interval startingAtOffset:(CGFloat)offset {
  LTParameterAssert(interval > 0);
  LTParameterAssert(offset >= 0);
  __block NSMutableArray *points = [NSMutableArray array];
  __block CGFloat nextDistance = offset;
  __block CGFloat prevDistance = 0;
  [self.distances enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *) {
    if (idx || !offset) {
      CGFloat distance = [obj doubleValue];
      if (distance >= nextDistance) {
        // Approximate (using linear interpolation) the key offset between the current sample and
        // the previous one, unless we're dealing with the first sample and there's no offset.
        CGFloat key = 0;
        if (idx > 0) {
          key = idx - 1 + ((nextDistance - prevDistance) / (distance - prevDistance));
        }
        LTPainterPoint *point = [self.routine valueAtKey:MIN(1, key / self.distances.count)];
        point.distanceFromStart = self.distanceFromStart + nextDistance;
        [points addObject:point];
        nextDistance = nextDistance + interval;
      }
      prevDistance = distance;
    }
  }];
  
  return points;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Segment from (%g,%g) to (%g,%g): method: %@",
          self.startPoint.contentPosition.x, self.startPoint.contentPosition.y,
          self.endPoint.contentPosition.x, self.endPoint.contentPosition.y, [self.routine class]];
}

@end
