// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTPrimitiveParameterizedObjectFactories.h"

#import "LTPrimitivePolynomialInterpolant.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark LTPrimitiveDegenerateInterpolantFactory
#pragma mark -

@implementation LTPrimitiveDegenerateInterpolantFactory

- (id<LTPrimitiveParameterizedObject>)primitiveParameterizedObjectsFromValues:(CGFloats)values {
  LTParameterAssert(values.size() == [[self class] numberOfRequiredValues],
                    @"Number of provided values (%lu) doesn't correspond to number of required "
                    "values (%lu)", (unsigned long)values.size(),
                    (unsigned long)[[self class] numberOfRequiredValues]);
  return [[LTPrimitivePolynomialInterpolant alloc] initWithCoefficients:{values.front()}];
}

+ (NSUInteger)numberOfRequiredValues {
  return 1;
}

+ (NSRange)intrinsicParametricRange {
  return NSMakeRange(0, 1);
}

@end

#pragma mark -
#pragma mark LTPrimitiveLinearInterpolantFactory
#pragma mark -

@implementation LTPrimitiveLinearInterpolantFactory

- (id<LTPrimitiveParameterizedObject>)primitiveParameterizedObjectsFromValues:(CGFloats)values {
  LTParameterAssert(values.size() == [[self class] numberOfRequiredValues],
                    @"Number of provided values (%lu) doesn't correspond to number of required "
                    "values (%lu)", (unsigned long)values.size(),
                    (unsigned long)[[self class] numberOfRequiredValues]);
  return [[LTPrimitivePolynomialInterpolant alloc]
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
#pragma mark LTPrimitiveCatmullRomInterpolantFactory
#pragma mark -

@implementation LTPrimitiveCatmullRomInterpolantFactory

/// M such that f(x) = [1, x, x^2, x^3] * M * [p0, p1, p2, p3].
/// @see http://www.lighthouse3d.com/tutorials/maths/catmull-rom-spline/
static const GLKMatrix4 kCoefficients = GLKMatrix4MakeAndTranspose(0, 1, 0, 0,
                                                                   -0.5, 0, 0.5, 0,
                                                                   1, -2.5, 2, -0.5,
                                                                   -0.5, 1.5, -1.5, 0.5);

- (id<LTPrimitiveParameterizedObject>)primitiveParameterizedObjectsFromValues:(CGFloats)values {
  LTParameterAssert(values.size() == [[self class] numberOfRequiredValues],
                    @"Number of provided values (%lu) doesn't correspond to number of required "
                    "values (%lu)", (unsigned long)values.size(),
                    (unsigned long)[[self class] numberOfRequiredValues]);
  GLKVector4 vector =
      GLKMatrix4MultiplyVector4(kCoefficients,
                                GLKVector4Make(values[0], values[1], values[2], values[3]));
  return [[LTPrimitivePolynomialInterpolant alloc] initWithCoefficients:{vector.v[3], vector.v[2],
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
