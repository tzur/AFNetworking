// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Protocol which should be implemented by immutable value objects constituting a mapping from a
/// single real-valued parameter to another real value.
///
/// A parametric object has a so-called intrinsic parametric range, a real-valued range
/// [\c minParametricValue, \c maxParametricValue], which maps to a special set of values. For
/// example, the intrinsic parametric range of a parametric object constituting a linear
/// interpolation between values \c x and \c y represents the convex combination of \c x and \c y.
/// In particular, \c minParametricValue maps to \c x, \c maxParametricValue maps to \c y and
/// parametric values outside the intrinsic range provide the corresponding values outside the
/// interval \c [x, y].
@protocol LTPrimitiveParameterizedObject <NSCopying, NSObject>

/// Returns the mapped value for the given parametric \c value.
- (CGFloat)floatForParametricValue:(CGFloat)parametricValue;

/// Lower bound of the intrinsic parametric range of this instance. Is smaller than or equal to
/// \c maxParametricValue.
@property (readonly, nonatomic) CGFloat minParametricValue;

/// Upper bound of the intrinsic parametric range of this instance. Is greater than or equal to
/// \c minParametricValue.
@property (readonly, nonatomic) CGFloat maxParametricValue;

@end

NS_ASSUME_NONNULL_END
