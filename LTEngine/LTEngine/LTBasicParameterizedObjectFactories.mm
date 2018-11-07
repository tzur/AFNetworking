// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBasicParameterizedObjectFactories.h"

#import "LTBasicPolynomialInterpolant.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark LTBasicDegenerateInterpolantFactory
#pragma mark -

@implementation LTBasicDegenerateInterpolantFactory

- (id<LTBasicParameterizedObject>)baseParameterizedObjectsFromValues:(std::vector<CGFloat>)values {
  LTParameterAssert(values.size() == [[self class] numberOfRequiredValues],
                    @"Number of provided values (%lu) doesn't correspond to number of required "
                    "values (%lu)", (unsigned long)values.size(),
                    (unsigned long)[[self class] numberOfRequiredValues]);
  return [[LTBasicPolynomialInterpolant alloc] initWithCoefficients:{values.front()}];
}

+ (NSUInteger)numberOfRequiredValues {
  return 1;
}

+ (NSRange)intrinsicParametricRange {
  return NSMakeRange(0, 1);
}

@end

#pragma mark -
#pragma mark LTBasicLinearInterpolantFactory
#pragma mark -

@implementation LTBasicLinearInterpolantFactory

- (id<LTBasicParameterizedObject>)baseParameterizedObjectsFromValues:(std::vector<CGFloat>)values {
  LTParameterAssert(values.size() == [[self class] numberOfRequiredValues],
                    @"Number of provided values (%lu) doesn't correspond to number of required "
                    "values (%lu)", (unsigned long)values.size(),
                    (unsigned long)[[self class] numberOfRequiredValues]);
  return [[LTBasicPolynomialInterpolant alloc]
          initWithCoefficients:{values.back() - values.front(), values.front()}];
}

+ (NSUInteger)numberOfRequiredValues {
  return 2;
}

+ (NSRange)intrinsicParametricRange {
  return NSMakeRange(0, 2);
}

@end

#pragma mark -
#pragma mark LTBasicCubicBezierInterpolantFactory
#pragma mark -

@implementation LTBasicCubicBezierInterpolantFactory

/// M such that f(x) = [1, x, x^2, x^3] * M * [p0, p1, p2, p3].
/// @see http://www.cs.cornell.edu/courses/cs4620/2013fa/lectures/16spline-curves.pdf
static const GLKMatrix4 kCubicBezierCoefficients = GLKMatrix4MakeAndTranspose(1, 0, 0, 0,
                                                                             -3, 3, 0, 0,
                                                                              3, -6, 3, 0,
                                                                             -1, 3, -3, 1);

- (id<LTBasicParameterizedObject>)baseParameterizedObjectsFromValues:(std::vector<CGFloat>)values {
  LTParameterAssert(values.size() == [[self class] numberOfRequiredValues],
                    @"Number of provided values (%lu) doesn't correspond to number of required "
                    "values (%lu)", (unsigned long)values.size(),
                    (unsigned long)[[self class] numberOfRequiredValues]);
  GLKVector4 vector =
      GLKMatrix4MultiplyVector4(kCubicBezierCoefficients,
                                GLKVector4Make(values[0], values[1], values[2], values[3]));
  return [[LTBasicPolynomialInterpolant alloc] initWithCoefficients:{vector.v[3], vector.v[2],
                                                                     vector.v[1], vector.v[0]}];
}

+ (NSUInteger)numberOfRequiredValues {
  return 4;
}

+ (NSRange)intrinsicParametricRange {
  return NSMakeRange(0, 4);
}

@end

#pragma mark -
#pragma mark LTBasicCatmullRomInterpolantFactory
#pragma mark -

@implementation LTBasicCatmullRomInterpolantFactory

/// M such that f(x) = [1, x, x^2, x^3] * M * [p0, p1, p2, p3].
/// @see http://www.lighthouse3d.com/tutorials/maths/catmull-rom-spline/
static const GLKMatrix4 kCatmullRomCoefficients = GLKMatrix4MakeAndTranspose(0, 1, 0, 0,
                                                                             -0.5, 0, 0.5, 0,
                                                                             1, -2.5, 2, -0.5,
                                                                             -0.5, 1.5, -1.5, 0.5);

- (id<LTBasicParameterizedObject>)baseParameterizedObjectsFromValues:(std::vector<CGFloat>)values {
  LTParameterAssert(values.size() == [[self class] numberOfRequiredValues],
                    @"Number of provided values (%lu) doesn't correspond to number of required "
                    "values (%lu)", (unsigned long)values.size(),
                    (unsigned long)[[self class] numberOfRequiredValues]);
  GLKVector4 vector =
      GLKMatrix4MultiplyVector4(kCatmullRomCoefficients,
                                GLKVector4Make(values[0], values[1], values[2], values[3]));
  return [[LTBasicPolynomialInterpolant alloc] initWithCoefficients:{vector.v[3], vector.v[2],
                                                                     vector.v[1], vector.v[0]}];
}

+ (NSUInteger)numberOfRequiredValues {
  return 4;
}

+ (NSRange)intrinsicParametricRange {
  return NSMakeRange(1, 2);
}

@end

#pragma mark -
#pragma mark LTBasicBSplineInterpolantFactory
#pragma mark -

@implementation LTBasicBSplineInterpolantFactory

/// M such that f(x) = [1, x, x^2, x^3] * M * [p0, p1, p2, p3].
/// @see http://www.cs.cornell.edu/courses/cs4620/2013fa/lectures/16spline-curves.pdf
static const GLKMatrix4 kBSplineCoefficients =
    GLKMatrix4MakeAndTranspose(1.0 / 6, 2.0 / 3, 1.0 / 6, 0,
                               -0.5, 0, 0.5, 0,
                               0.5, -1, 0.5, 0,
                               -1.0 / 6, 0.5, -0.5, 1.0 / 6);

- (id<LTBasicParameterizedObject>)baseParameterizedObjectsFromValues:(std::vector<CGFloat>)values {
  LTParameterAssert(values.size() == [[self class] numberOfRequiredValues],
                    @"Number of provided values (%lu) doesn't correspond to number of required "
                    "values (%lu)", (unsigned long)values.size(),
                    (unsigned long)[[self class] numberOfRequiredValues]);
  GLKVector4 vector =
      GLKMatrix4MultiplyVector4(kBSplineCoefficients,
                                GLKVector4Make(values[0], values[1], values[2], values[3]));
  return [[LTBasicPolynomialInterpolant alloc] initWithCoefficients:{vector.v[3], vector.v[2],
                                                                     vector.v[1], vector.v[0]}];
}

+ (NSUInteger)numberOfRequiredValues {
  return 4;
}

+ (NSRange)intrinsicParametricRange {
  return NSMakeRange(1, 2);
}

@end

NS_ASSUME_NONNULL_END
