// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTInterpolationRoutine.h"

/// Implementation of a degenerate interpolation routine, accepting a single keyframes and returning
/// it througout the interval.
@interface LTDegenerateInterpolationRoutine : LTInterpolationRoutine
@end

/// Factory for creating degenerate interpolation routine instances.
@interface LTDegenerateInterpolationRoutineFactory : NSObject <LTInterpolationRoutineFactory>
@end
