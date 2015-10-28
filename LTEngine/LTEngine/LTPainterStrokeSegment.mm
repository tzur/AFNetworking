// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainterStrokeSegment.h"

#import "LTPolynomialInterpolant.h"
#import "LTPainterPoint.h"

@interface LTPainterStrokeSegment () {
  CGFloats _distances;
}

/// Index of the segment in the stroke.
@property (readwrite, nonatomic) NSUInteger index;

/// Distance (in pixels) of the segment's starting point from the stroke's starting point.
@property (readwrite, nonatomic) CGFloat distanceFromStart;

/// Approximated length of the segment.
@property (readwrite, nonatomic) CGFloat length;

/// Starting point of the segment.
@property (strong, readwrite, nonatomic) LTPainterPoint *startPoint;

/// Ending point of the segment.
@property (strong, nonatomic) LTPainterPoint *endPoint;

/// Interpolant used for generating points along the segment.
@property (strong, nonatomic) LTPolynomialInterpolant *interpolant;

/// Array of distances of each sampling point along the segment.
@property (readonly, nonatomic) CGFloats &distances;

@end

@implementation LTPainterStrokeSegment

/// Number of sample points used for approximating the length of the segment.
static const NSUInteger kNumSamplesForLengthEstimation = 500;

- (instancetype)initWithSegmentIndex:(NSUInteger)index distanceFromStart:(CGFloat)distance
                      andInterpolant:(LTPolynomialInterpolant *)interpolant {
  if (self = [super init]) {
    LTParameterAssert(interpolant);
    LTParameterAssert(distance >= 0);
    self.index = index;
    self.distanceFromStart = distance;
    self.interpolant = interpolant;
    self.startPoint = [interpolant valueAtKey:0];
    self.endPoint = [interpolant valueAtKey:1];
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

  CGFloats xPositions = [self.interpolant valuesOfPropertyNamed:@"contentPositionX" atKeys:keys];
  CGFloats yPositions = [self.interpolant valuesOfPropertyNamed:@"contentPositionY" atKeys:keys];
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
            [self.interpolant valueAtKey:std::clamp(key / self.distances.size(), 0, 1)];
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
          self.endPoint.contentPosition.x, self.endPoint.contentPosition.y,
          [self.interpolant class]];
}

@end
