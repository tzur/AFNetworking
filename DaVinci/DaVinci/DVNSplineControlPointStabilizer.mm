// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNSplineControlPointStabilizer.h"

#import <LTEngine/LTSplineControlPoint+AttributeKeys.h>

NS_ASSUME_NONNULL_BEGIN

typedef std::vector<CGPoint>::size_type CGPointVectorType;

@interface DVNSplineControlPointStabilizer ()

/// Location of the last control point processed and returned. Initial value is \c CGPointNull. Is
/// reset when end indication is \c YES.
@property (nonatomic) CGPoint previousLocation;

/// Attributes of the last control point processed and returned. Initial value is \c nil. Is reset
/// when end indication is \c YES.
@property (strong, nonatomic, nullable) NSDictionary<NSString *, NSNumber *> *previousAttributes;

/// Factor used for smoothing the last control point processed and returned. Initial value is \c 0.
/// Is reset when end indication is \c YES.
@property (nonatomic) CGFloat previousSmoothingFactor;

@end

@implementation DVNSplineControlPointStabilizer

- (instancetype)init {
  if (self = [super init]) {
    [self reset];
  }
  return self;
}

- (void)reset {
  self.previousLocation = CGPointNull;
  self.previousAttributes = nil;
  self.previousSmoothingFactor = 0;
}

- (NSArray<LTSplineControlPoint *> *)pointsForPoints:(NSArray<LTSplineControlPoint *> *)points
                               smoothedWithIntensity:(CGFloat)smoothingIntensity end:(BOOL)end {
  LTParameterAssert(points.count);
  LTParameterAssert(smoothingIntensity > 0 && smoothingIntensity <= 1,
                    @"Smoothing intensity (%g) must be in range (0, 1]", smoothingIntensity);

  NSMutableArray<LTSplineControlPoint *> *smoothedPoints =
      [NSMutableArray arrayWithCapacity:points.count];

  for (LTSplineControlPoint *controlPoint in points) {
    self.previousSmoothingFactor = [self smoothingFactorFromPoint:controlPoint
                                               smoothingIntensity:smoothingIntensity];
    self.previousLocation = [self locationFromLocation:controlPoint.location
                                    smoothedWithFactor:self.previousSmoothingFactor];
    self.previousAttributes = [self attributesFromAttributes:controlPoint.attributes
                                          smoothedWithFactor:self.previousSmoothingFactor];
    [smoothedPoints addObject:[[LTSplineControlPoint alloc]
                               initWithTimestamp:controlPoint.timestamp
                               location:self.previousLocation
                               attributes:self.previousAttributes]];
  }

  if (end) {
    [self reset];
  }

  return smoothedPoints;
}

- (CGPoint)locationFromLocation:(CGPoint)location smoothedWithFactor:(CGFloat)smoothingFactor {
  return CGPointIsNull(self.previousLocation) ? location :
      (1 - smoothingFactor) * location + smoothingFactor * self.previousLocation;
}

- (NSDictionary<NSString *, NSNumber *> *)
    attributesFromAttributes:(NSDictionary<NSString *, NSNumber *> *)attributes
    smoothedWithFactor:(CGFloat)smoothingFactor {
  if (!self.previousAttributes) {
    return attributes;
  }

  NSMutableDictionary<NSString *, NSNumber *> *mutableAttributes = [attributes mutableCopy];
  [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *value,
                                                               BOOL *) {
    mutableAttributes[key] = @((1 - smoothingFactor) * [value CGFloatValue] +
        smoothingFactor * [self.previousAttributes[key] CGFloatValue]);
  }];
  return mutableAttributes;
}

static CGFloat DVNParametricValue(CGFloat x, CGFloat min, CGFloat intervalLength) {
  return (x - min) / intervalLength;
}

static CGFloat DVNLinearCombination(CGFloat x, CGFloat min, CGFloat max) {
  return (1 - x) * min + x * max;
}

/// Heuristic value determining the minimum value, in point units of the screen coordinate system,
/// of the speed interval used for computation of the smoothing factor.
static const CGFloat kMinSpeedForSmoothingFactorInterpolation = 50;

/// Heuristic value determining the length, in point units of the screen coordinate system, of the
/// speed interval used for computation of the smoothing factor.
static const CGFloat kSpeedIntervalLengthForSmoothingFactorInterpolation = 950;

/// Multiplicative factor used to compute the smoothing intensity value for low spline control point
/// speeds.
static const CGFloat kSmoothingIntensityLowSpeedFactor = 0.6;

/// Factor preventing that the computed smoothing factor is \c 1 which would result in the creation
/// of a new spline control point equal to the previous one.
static const CGFloat kFactorPreventingStagnancy = 0.99;

- (CGFloat)smoothingFactorFromPoint:(LTSplineControlPoint *)point
                 smoothingIntensity:(CGFloat)smoothingIntensity {
  CGFloat speed =
      [point.attributes[[LTSplineControlPoint keyForSpeedInScreenCoordinates]] CGFloatValue];
  CGFloat parametricValue =
      std::clamp(DVNParametricValue(speed, kMinSpeedForSmoothingFactorInterpolation,
                                    kSpeedIntervalLengthForSmoothingFactorInterpolation), 0, 1);
  /// In order to achieve a spline fitting to the actual points more closely, the smoothing factor
  /// is decreased for lower speed values.
  CGFloat minSmoothingFactor = kSmoothingIntensityLowSpeedFactor * smoothingIntensity;
  CGFloat smoothingFactor = kFactorPreventingStagnancy * DVNLinearCombination(parametricValue,
                                                                              minSmoothingFactor,
                                                                              smoothingIntensity);
  /// In order to achieve a smooth transition of the computed smoothing factor, it is ensured that
  /// the decrease/increase is at most 50%.
  return self.previousSmoothingFactor ?
      std::clamp(smoothingFactor, 0.5 * self.previousSmoothingFactor,
                 1.5 * self.previousSmoothingFactor) :
      smoothingFactor;
}

@end

NS_ASSUME_NONNULL_END
