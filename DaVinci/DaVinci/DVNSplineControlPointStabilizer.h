// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTSplineControlPoint;

/// Object mapping consecutively provided \c LTSplineControlPoint objects to updated
/// \c LTSplineControlPoint instances in a way which yields smoother splines when using the returned
/// instances for spline creation.
@interface DVNSplineControlPointStabilizer : NSObject

/// Returns an ordered collection of \c LTSplineControlPoint from the given \c points such that
/// splines created from the returned points are smoother than the ones created from the given
/// \c points. The smoothness of the constructible spline depends on the given \c smoothingIntensity
/// which must be in <tt>(0, 1]<tt>. The smoothness of the spline constructible from the returned
/// points increases proportionally to the given \c smoothingIntensity. For the minimum value of
/// \c smoothingIntensity, the spline constructible from the returned points is equal to the one
/// constructible from the given \c points, up to a negligible deviation.
///
/// The smoothing is performed by converting each \c LTSplineControlPoint instance into a new
/// \c LTSplineControlPoint whose \c location is a weighted sum of the previously provided points.
///
/// The given \c points must contain at least one \c LTSplineControlPoint.
- (NSArray<LTSplineControlPoint *> *)pointsForPoints:(NSArray<LTSplineControlPoint *> *)points
                               smoothedWithIntensity:(CGFloat)smoothingIntensity end:(BOOL)end;

@end

NS_ASSUME_NONNULL_END
