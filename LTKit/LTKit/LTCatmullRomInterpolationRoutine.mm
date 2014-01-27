// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCatmullRomInterpolationRoutine.h"

@implementation LTCatmullRomInterpolationRoutine

/// M such that f(x) = [1, x, x^2, x^3] * M * [p0, p1, p2, p3].
/// See: http://www.lighthouse3d.com/tutorials/maths/catmull-rom-spline/
static const double m00 = 0;
static const double m01 = 1;
static const double m02 = 0;
static const double m03 = 0;
static const double m10 = -0.5;
static const double m11 = 0;
static const double m12 = 0.5;
static const double m13 = 0;
static const double m20 = 1;
static const double m21 = -2.5;
static const double m22 = 2;
static const double m23 = -0.5;
static const double m30 = -0.5;
static const double m31 = 1.5;
static const double m32 = -1.5;
static const double m33 = 0.5;

- (NSDictionary *)calculateCoefficientsForKeyFrames:(NSArray *)keyFrames {
  NSArray *propertiesToInterpolate = [keyFrames.firstObject propertiesToInterpolate];
  NSMutableDictionary *coefficients =
  [NSMutableDictionary dictionaryWithCapacity:propertiesToInterpolate.count];
  for (NSString *propertyName in propertiesToInterpolate) {
    // TODO:(yaron) please decide if you prefer to use GLKMatrix4 and GLKVector4 for readability,
    // with the drawback of working with floats instead of doubles.
    double v0 = [[keyFrames[0] valueForKey:propertyName] doubleValue];
    double v1 = [[keyFrames[1] valueForKey:propertyName] doubleValue];
    double v2 = [[keyFrames[2] valueForKey:propertyName] doubleValue];
    double v3 = [[keyFrames[3] valueForKey:propertyName] doubleValue];
    coefficients[propertyName] = @[@(m30 * v0 + m31 * v1 + m32 * v2 + m33 * v3),
                                   @(m20 * v0 + m21 * v1 + m22 * v2 + m23 * v3),
                                   @(m10 * v0 + m11 * v1 + m12 * v2 + m13 * v3),
                                   @(m00 * v0 + m01 * v1 + m02 * v2 + m03 * v3)];
  }
  return coefficients;
}

+ (NSUInteger)expectedKeyFrames {
  return 4;
}

@end
