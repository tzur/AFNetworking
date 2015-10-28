// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCatmullRomInterpolant.h"

#import "LTInterpolatableObject.h"

@implementation LTCatmullRomInterpolant

/// M such that f(x) = [1, x, x^2, x^3] * M * [p0, p1, p2, p3].
/// See: http://www.lighthouse3d.com/tutorials/maths/catmull-rom-spline/
static const GLKMatrix4 M = GLKMatrix4MakeAndTranspose(0, 1, 0, 0,
                                                       -0.5, 0, 0.5, 0,
                                                       1, -2.5, 2, -0.5,
                                                       -0.5, 1.5, -1.5, 0.5);

- (NSDictionary *)calculateCoefficientsForKeyFrames:(NSArray *)keyFrames {
  NSArray *propertiesToInterpolate = [keyFrames.firstObject propertiesToInterpolate];
  NSMutableDictionary *coefficients =
  [NSMutableDictionary dictionaryWithCapacity:propertiesToInterpolate.count];
  for (NSString *propertyName in propertiesToInterpolate) {
    GLKVector4 v = GLKVector4Make([[keyFrames[0] valueForKey:propertyName] doubleValue],
                                  [[keyFrames[1] valueForKey:propertyName] doubleValue],
                                  [[keyFrames[2] valueForKey:propertyName] doubleValue],
                                  [[keyFrames[3] valueForKey:propertyName] doubleValue]);
    GLKVector4 Mv = GLKMatrix4MultiplyVector4(M, v);
    coefficients[propertyName] = @[@(Mv.v[3]), @(Mv.v[2]), @(Mv.v[1]), @(Mv.v[0])];
  }
  return coefficients;
}

+ (NSUInteger)expectedKeyFrames {
  return 4;
}

+ (NSRange)rangeOfIntervalInWindow {
  return NSMakeRange(1, 2);
}

@end

@implementation LTCatmullRomInterpolantFactory

- (LTPolynomialInterpolant *)interpolantWithKeyFrames:(NSArray *)keyFrames {
  return [[LTCatmullRomInterpolant alloc] initWithKeyFrames:keyFrames];
}

- (NSUInteger)expectedKeyFrames {
  return [LTCatmullRomInterpolant expectedKeyFrames];
}

- (NSRange)rangeOfIntervalInWindow {
  return [LTCatmullRomInterpolant rangeOfIntervalInWindow];
}

@end
