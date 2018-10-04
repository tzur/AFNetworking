// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSpeedBasedSplineControlPointBuffer.h"

#import "LTSplineControlPoint+AttributeKeys.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTSpeedBasedSplineControlPointBuffer ()

/// Control points currently buffered by this instance. Is empty if no control points are currently
/// buffered.
@property (strong, nonatomic) NSArray<LTSplineControlPoint *> *bufferedControlPoints;

@end

@implementation LTSpeedBasedSplineControlPointBuffer

#pragma mark -
#pragma mark Initialization
#pragma mark -

/// Maximum speed used for default initialization.
static const CGFloat kDefaultMaxSpeed = 5000;

/// Time intervals used for default initialization.
static const lt::Interval<NSTimeInterval> kDefaultTimeIntervals =
    lt::Interval<NSTimeInterval>({(NSTimeInterval)1.0 / 120, (NSTimeInterval)1.0 / 20});

- (instancetype)init {
  return [self initWithMaxSpeed:kDefaultMaxSpeed timeIntervals:kDefaultTimeIntervals];
}
  - (instancetype)initWithMaxSpeed:(CGFloat)maxSpeed
                     timeIntervals:(lt::Interval<NSTimeInterval>)timeIntervals {
  LTParameterAssert(maxSpeed > 0, @"Maxium speed (%g) must be non-negative", maxSpeed);
  if (self = [super init]) {
    _maxSpeed = maxSpeed;
    _timeIntervals = timeIntervals;
    [self reset];
  }
  return self;
}

#pragma mark -
#pragma mark Public API
#pragma mark -

- (NSArray<LTSplineControlPoint *> *)
    processAndPossiblyBufferControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints
    flush:(BOOL)flush {
  if (flush) {
    auto bufferedControlPoints = self.bufferedControlPoints;
    [self reset];
    return [bufferedControlPoints arrayByAddingObjectsFromArray:controlPoints];
  }

  if (!controlPoints.count) {
    return @[];
  }

  NSArray<LTSplineControlPoint *> *allControlPoints =
      [self.bufferedControlPoints arrayByAddingObjectsFromArray:controlPoints];
  NSTimeInterval comparisonTimestamp = allControlPoints.lastObject.timestamp;

  NSUInteger index = 0;
  for (NSUInteger i = 0; i < allControlPoints.count; ++i) {
    LTSplineControlPoint *controlPoint = allControlPoints[i];
    CGFloat speedInViewCoordinates =
        [controlPoint.attributes[[LTSplineControlPoint keyForSpeedInScreenCoordinates]]
         CGFloatValue];
    CGFloat factor = std::min(speedInViewCoordinates / self.maxSpeed, (CGFloat)1.0);
    if (comparisonTimestamp - controlPoint.timestamp <= self.timeIntervals.valueAt(factor)) {
      // The control points before the currently checked one are too old and should therefore be
      // returned.
      break;
    }
    ++index;
  }

  NSRange rangeOfReturnedControlPoints = NSMakeRange(0, index);
  NSRange rangeOfBufferedControlPoints = NSMakeRange(index, allControlPoints.count - index);
  self.bufferedControlPoints = [allControlPoints subarrayWithRange:rangeOfBufferedControlPoints];
  return [allControlPoints subarrayWithRange:rangeOfReturnedControlPoints];
}

#pragma mark -
#pragma mark Auxiliary Methods
#pragma mark -

- (void)reset {
  self.bufferedControlPoints = @[];
}

@end

NS_ASSUME_NONNULL_END
