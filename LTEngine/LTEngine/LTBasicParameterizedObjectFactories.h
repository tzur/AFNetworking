// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBasicParameterizedObjectFactory.h"

NS_ASSUME_NONNULL_BEGIN

/// Factory for creating basic degenerate interpolants, accepting a single value and returning it
/// for any query key.
@interface LTBasicDegenerateInterpolantFactory : NSObject <LTBasicParameterizedObjectFactory>
@end

/// Factory for creating basic linear interpolants, accepting two values \c A and \c B and
/// performing a linear interpolation between them. The intrinsic parametric range of any returned
/// interpolant is [\c 0, \c 1], i.e. \c floatForParametricValue: returns \c A for value \c 0, and
/// \c B for \c 1.
@interface LTBasicLinearInterpolantFactory : NSObject <LTBasicParameterizedObjectFactory>
@end

/// Factory for creating basic Catmull-Rom splines. A Catmull-Rom spline is a polynomial interpolant
/// defined by four values \c A, \c B, \c C, and \c D serving as control points for the
/// interpolation. \c A and \c D serve as auxiliary control points, while the relevant spline
/// segment is conceptually defined between \c B and \c C. The intrinsic parametric range of any
/// returned interpolant is [\c 0, \c 1], i.e. \c floatForParametricValue: returns \c B for value
/// \c 0, and \c C for \c 1.
///
/// @see https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline
/// @see http://www.lighthouse3d.com/tutorials/maths/catmull-rom-spline
@interface LTBasicCatmullRomInterpolantFactory : NSObject <LTBasicParameterizedObjectFactory>
@end

NS_ASSUME_NONNULL_END
