// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTInterpolationRoutine.h"

/// Implementation of a linear interpolation routine, accepting two keyframes and performing a
/// linear interpolation between them.
@interface LTLinearInterpolationRoutine : LTInterpolationRoutine
@end

/// Factory for creating linear interpolation routine instances.
@interface LTLinearInterpolationRoutineFactory : NSObject <LTInterpolationRoutineFactory>
@end
