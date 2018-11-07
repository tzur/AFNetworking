// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBasicPolynomialInterpolant.h"

#import <LTKit/LTHashExtensions.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTBasicPolynomialInterpolant () {
  /// Coefficients determining the polynomial used for interpolation.
  std::vector<CGFloat> _coefficients;
}
@end

@implementation LTBasicPolynomialInterpolant

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithCoefficients:(std::vector<CGFloat>)coefficients {
  LTParameterAssert(coefficients.size() > 0, @"At least one coefficient must be provided.");

  if (self = [super init]) {
    _coefficients = coefficients;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTBasicPolynomialInterpolant *)interpolant {
  if (self == interpolant) {
    return YES;
  }

  if (![interpolant isMemberOfClass:[self class]]) {
    return NO;
  }

  return _coefficients == interpolant->_coefficients;
}

- (NSUInteger)hash {
  return std::hash<std::vector<CGFloat>>()(_coefficients);
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark LTBasicParameterizedObject
#pragma mark -

- (CGFloat)floatForParametricValue:(CGFloat)parametricValue {
  CGFloat result = 0;
  for (const CGFloat &coefficient : _coefficients) {
    result = parametricValue * result + coefficient;
  }
  return result;
}

- (CGFloat)minParametricValue {
  return 0;
}

- (CGFloat)maxParametricValue {
  return 1;
}

@end

NS_ASSUME_NONNULL_END
