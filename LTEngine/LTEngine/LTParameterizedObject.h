// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Represents mapping from key to boxed \c CGFloat returned by parameterized objects.
typedef NSDictionary<NSString *, NSNumber *> LTParameterizationKeyToValue;

/// Represents mapping from key to ordered collection of boxed \c CGFloat returned by parameterized
/// objects.
typedef NSDictionary<NSString *, NSArray<NSNumber *> *> LTParameterizationKeyToValues;

/// Protocol which should be implemented by objects constituting a mapping from a single real-valued
/// parameter \c t to a mapping from keys to real values. In practice, a parameterized object
/// usually consists of primitive parameterized objects (e.g. polynomial interpolants) each of which
/// is addressed by a unique key and which is used to compute a specific result value for a given
/// value of \c t. A convenient way to think of parameterized objects is as mapping from a real
/// value to a point in \c R^n, where the keys represent the axes names of the underlying coordinate
/// system.
///
/// A parametric object has a so-called intrinsic parametric range, a real-valued range
/// [\c minParametricValue, \c maxParametricValue], which maps to a special set of result mappings.
///
/// Example 1: in a parametric object constituting a linear interpolation between a point \c P and
/// a point \c Q, the intrinsic parametric range represents the convex combination of \c P and \c Q.
/// In particular, \c minParametricValue maps to \c P and \c maxParametricValue maps to \c Q and
/// parametric values outside the intrinsic range provide the corresponding points outside the line
/// segment \c PQ.
///
/// Example 2: in a parametric object representing a Catmull-Rom spline composed of control points
/// \c P, \c Q, \c R, and \c S, the intrinsic parametric range represents the segment from \c Q to
/// \c R. In particular, \c minParametricValue maps to \c Q and \c maxParametricValue maps to \c R
/// and parametric values outside the intrinsic range provide the extrapolated corresponding points.
@protocol LTParameterizedObject <NSCopying, NSObject>

/// Returns the mapping from all \c parameterizationKeys to the corresponding real values, for the
/// given parametric \c value.
- (LTParameterizationKeyToValue *)mappingForParametricValue:(CGFloat)value;

/// Returns the mapping from all \c parameterizationKeys to ordered collections of the corresponding
/// real values, for the given parametric \c values.
///
/// @note This is a convenience method aimed at improving the performance of mapping retrieval for
/// several parametric values.
- (LTParameterizationKeyToValues *)mappingForParametricValues:(const CGFloats &)values;

/// Returns the real value for the mapped \c key, for the given parametric \c value. The given
/// \c key must be in the set of \c parameterizationKeys.
- (CGFloat)floatForParametricValue:(CGFloat)value key:(NSString *)key;

/// Returns the values for the mapped \c key, for the given parametric \c values. The given \c key
/// must be in the set of \c parameterizationKeys.
///
/// @note This is a convenience method aimed at improving the performance of value retrieval for
/// several parametric values.
- (CGFloats)floatsForParametricValues:(const CGFloats &)values key:(NSString *)key;

/// Keys of the mappings returned by this object.
@property (readonly, nonatomic) NSSet<NSString *> *parameterizationKeys;

/// Lower bound of the intrinsic parametric range of this instance. Is smaller than or equal to
/// \c maxParametricValue.
@property (readonly, nonatomic) CGFloat minParametricValue;

/// Upper bound of the intrinsic parametric range of this instance. Is greater than or equal to
/// \c minParametricValue.
@property (readonly, nonatomic) CGFloat maxParametricValue;

@end

NS_ASSUME_NONNULL_END
