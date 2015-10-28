// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPolynomialInterpolant.h"

/// Implementation of a Catmull-Rom spline interpolant, accepting four keyframes and performing an
/// interpolation between the second and third key frames of the Catmull-Rom spline constructed from
/// all four (Such that the value at \c 0 is the second key frame, and the value at \c 1 is the
/// third one.
@interface LTCatmullRomInterpolationRoutine : LTPolynomialInterpolant
@end

/// Factory for creating Catmull-Rom spline interpolant instances.
@interface LTCatmullRomInterpolationRoutineFactory : NSObject <LTPolynomialInterpolantFactory>
@end
