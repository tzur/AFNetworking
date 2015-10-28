// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPolynomialInterpolant.h"

/// Implementation of a linear interpolant, accepting two keyframes and performing a linear
/// interpolation between them.
@interface LTLinearInterpolationRoutine : LTPolynomialInterpolant
@end

/// Factory for creating linear interpolant instances.
@interface LTLinearInterpolationRoutineFactory : NSObject <LTPolynomialInterpolantFactory>
@end
