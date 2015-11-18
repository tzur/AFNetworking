// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTPrimitivePolynomialInterpolant.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTPrimitivePolynomialInterpolant () {
  /// Coefficients determining the polynomial used for interpolation.
  CGFloats _coefficients;
}
@end

@implementation LTPrimitivePolynomialInterpolant

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithCoefficients:(CGFloats)coefficients {
  LTParameterAssert(coefficients.size() > 0, @"At least one coefficient must be provided.");

  if (self = [super init]) {
    _coefficients = coefficients;
  }
  return self;
}

#pragma mark -
#pragma mark LTPrimitiveParameterizedObject
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
