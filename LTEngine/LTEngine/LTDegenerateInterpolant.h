// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPolynomialInterpolant.h"

/// Implementation of a degenerate interpolant, accepting a single keyframe and returning it
/// througout the interval.
@interface LTDegenerateInterpolant : LTPolynomialInterpolant
@end

/// Factory for creating degenerate interpolant instances.
@interface LTDegenerateInterpolantFactory : NSObject <LTPolynomialInterpolantFactory>
@end
