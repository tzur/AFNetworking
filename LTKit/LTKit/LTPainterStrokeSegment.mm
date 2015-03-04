// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainterStrokeSegment.h"

#import "LTCGExtensions.h"
#import "LTInterpolationRoutine.h"
#import "LTPainterPoint.h"

@interface LTPainterStrokeSegment () {
  CGFloats _distances;
}

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
@property (readonly, nonatomic) CGFloats &distances;

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
    [self fillDistances:&_distances WithNumberOfSamples:kNumSamplesForLengthEstimation];
    self.length = self.distances.back();
  }
  return self;
}

- (void)fillDistances:(CGFloats *)distances WithNumberOfSamples:(NSUInteger)count {
  LTParameterAssert(count > 1);
  LTParameterAssert(distances);
  CGFloats keys;
  CGFloat step = 1.0 / count;
  for (NSUInteger i = 1; i < count; ++i) {
    keys.push_back(i * step);
  }

  CGFloats xPositions = [self.routine valuesOfCGFloatPropertyNamed:@"contentPositionX" atKeys:keys];
  CGFloats yPositions = [self.routine valuesOfCGFloatPropertyNamed:@"contentPositionY" atKeys:keys];
  LTAssert(xPositions.size() == yPositions.size());
  
  CGFloat length = 0;
  CGPoint previousPoint = self.startPoint.contentPosition;
  distances->clear();
  distances->push_back(0);
  for (auto x = xPositions.cbegin(), y = yPositions.cbegin(); x < xPositions.cend(); ++x, ++y) {
    CGPoint point = CGPointMake(*x, *y);
    length += CGPointDistance(previousPoint, point);
    distances->push_back(length);
    previousPoint = point;
  }
}

- (NSArray *)pointsWithInterval:(CGFloat)interval startingAtOffset:(CGFloat)offset {
  LTParameterAssert(interval > 0);
  LTParameterAssert(offset >= 0);
  NSMutableArray *points = [NSMutableArray array];
  CGFloat nextDistance = offset;
  CGFloat prevDistance = 0;
  for (NSUInteger idx = 0; idx < self.distances.size(); ++idx) {
    if (idx || !offset) {
      CGFloat distance = self.distances[idx];
      if (distance >= nextDistance) {
        // Approximate (using linear interpolation) the key offset between the current sample and
        // the previous one, unless we're dealing with the first sample and there's no offset.
        CGFloat key = 0;
        if (idx > 0) {
          key = idx - 1 + ((nextDistance - prevDistance) / (distance - prevDistance));
        }

        // TODO:(amit) find out why the unclamped value might be negative in certain scenarios for
        // brushes with very small scale and spacing.
        LTPainterPoint *point =
            [self.routine valueAtKey:std::clamp(key / self.distances.size(), 0, 1)];
        point.distanceFromStart = self.distanceFromStart + nextDistance;
        [points addObject:point];
        nextDistance = nextDistance + interval;
      }
      prevDistance = distance;
    }
  }
  
  return points;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Segment from (%g,%g) to (%g,%g): method: %@",
          self.startPoint.contentPosition.x, self.startPoint.contentPosition.y,
          self.endPoint.contentPosition.x, self.endPoint.contentPosition.y, [self.routine class]];
}

@end
