// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTPeriodicFloatSet.h"

#import <LTKit/LTHashExtensions.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct {
  /// Minimum discrete value to return.
  CGFloat startValue;
  /// Number of remaining discrete values in the currently processed sequence.
  NSUInteger numberOfRemainingValues;
} LTDiscreteSequenceStartInfo;

@interface LTPeriodicFloatSet ()

/// Distance of the first values of two adjacent sequences.
@property (readonly, nonatomic) CGFloat distanceOfFirstValues;

@end

@implementation LTPeriodicFloatSet

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithPivotValue:(CGFloat)pivotValue
         numberOfValuesPerSequence:(NSUInteger)numberOfValuesPerSequence
                     valueDistance:(CGFloat)valueDistance
                  sequenceDistance:(CGFloat)sequenceDistance {
  LTParameterAssert(numberOfValuesPerSequence > 0,
                    @"Number of values per sequence must be positive");
  LTParameterAssert(valueDistance > 0, @"Distance between consecutive values must be positive");
  LTParameterAssert(sequenceDistance > 0,
                    @"Distance between consecutive sequences must be positive");
  if (self = [super init]) {
    _pivotValue = pivotValue;
    _numberOfValuesPerSequence = numberOfValuesPerSequence;
    _valueDistance = valueDistance;
    _sequenceDistance = sequenceDistance;
    _distanceOfFirstValues = (numberOfValuesPerSequence - 1) * valueDistance + sequenceDistance;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTPeriodicFloatSet *)floatSet {
  if (floatSet == self) {
    return YES;
  }

  if (![floatSet isKindOfClass:[LTPeriodicFloatSet class]]) {
    return NO;
  }

  return self.pivotValue == floatSet.pivotValue &&
      self.numberOfValuesPerSequence == floatSet.numberOfValuesPerSequence &&
      self.valueDistance == floatSet.valueDistance &&
      self.sequenceDistance == floatSet.sequenceDistance;
}

- (NSUInteger)hash {
  return std::hash<CGFloat>()(self.pivotValue) ^ self.numberOfValuesPerSequence ^
      std::hash<CGFloat>()(self.valueDistance) ^ std::hash<CGFloat>()(self.sequenceDistance);
}

#pragma mark -
#pragma mark LTFloatSet
#pragma mark -

- (std::vector<CGFloat>)discreteValuesInInterval:(const lt::Interval<CGFloat> &)interval {
  LTDiscreteSequenceStartInfo startInfo = [self startInfoForInterval:interval];
  CGFloat currentValue = startInfo.startValue;
  NSUInteger numberOfRemainingValues = startInfo.numberOfRemainingValues;

  std::vector<CGFloat> result;

  while (currentValue <= interval.sup()) {
    if (interval.contains(currentValue)) {
      result.push_back(currentValue);
    }
    numberOfRemainingValues--;
    if (numberOfRemainingValues) {
      currentValue += self.valueDistance;
    } else {
      currentValue += self.sequenceDistance;
      numberOfRemainingValues = self.numberOfValuesPerSequence;
    }
  }

  return result;
}

- (LTDiscreteSequenceStartInfo)startInfoForInterval:(const lt::Interval<CGFloat> &)interval {
  // The set is defined as \c {p + k * d + m * s | p in R, k in {0, 1, ..., n - 1}, d in R^+,
  // m in Z, s in R^+, s > (n - 1) * d}, where \c n is the number of values per sequence.
  // For the given \c interval, the intersection of the set with the interval must be returned.
  // Hence, \c k and \c m must be computed such that \c p + k * d + m * s is the maximum value
  // smaller than or equal to \c interval.inf().

  // Solving for m: setting \c k to \c 0 yields:
  // \c p + m * s <= interval.inf() <=> m <= (interval.inf() - p) / s
  NSInteger m = std::floor((interval.inf() - self.pivotValue) / self.distanceOfFirstValues);

  CGFloat firstValueOfSequence = self.pivotValue + m * self.distanceOfFirstValues;

  // Solving for \c k: p + k * d + m * s <= interval.inf() <=> k <= (interval.inf() - p - m * s) / d
  NSInteger k = std::floor(interval.inf() - firstValueOfSequence) / self.valueDistance;
  LTAssert(k >= 0, @"Computed value (%ld) must be non-negative", (long)k);

  if ((NSUInteger)k >= self.numberOfValuesPerSequence) {
    return {
      .startValue = firstValueOfSequence,
      .numberOfRemainingValues = self.numberOfValuesPerSequence
    };
  }
  CGFloat startValue = self.pivotValue + k * self.valueDistance + m * self.distanceOfFirstValues;
  LTAssert(startValue <= interval.inf(),
           @"Value (%f) computed for p = %f, k = %ld, d = %f, m = %ld, s = %f must be smaller than "
           "minimum value of interval (%f)", startValue, self.pivotValue, (long)k,
           self.valueDistance, (long)m, self.distanceOfFirstValues, interval.inf());

  return {.startValue = startValue, .numberOfRemainingValues = self.numberOfValuesPerSequence - k};
}

@end

NS_ASSUME_NONNULL_END
