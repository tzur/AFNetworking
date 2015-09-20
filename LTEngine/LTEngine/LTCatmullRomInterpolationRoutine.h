// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTInterpolationRoutine.h"

/// Implementation of a Catmull-Rom spline interpolation routine, accepting four keyframes and
/// performing an interpolation between the second and third key frames of the Catmull-Rom spline
/// constructed from all four (Such that the value at \c 0 is the second key frame, and the value at
/// \c 1 is the third one.
@interface LTCatmullRomInterpolationRoutine : LTInterpolationRoutine
@end

/// Factory for creating linear interpolation routine instances.
@interface LTCatmullRomInterpolationRoutineFactory : NSObject <LTInterpolationRoutineFactory>
@end
