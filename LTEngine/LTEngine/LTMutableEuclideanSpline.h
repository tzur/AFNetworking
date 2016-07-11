// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTEuclideanSplineControlPoint.h"
#import "LTParameterizedObject.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTInterpolatableObject;

@class LTCompoundParameterizedObjectFactory<ObjectType:id<LTInterpolatableObject>>;

/// Factory constructing compound parameterized objects from \c LTEuclideanSplineControlPoint
/// objects.
typedef LTCompoundParameterizedObjectFactory<LTEuclideanSplineControlPoint *>
    LTEuclideanSplineControlPointFactory;

/// Mutable, univariately parameterized object constituting an extensible spline consisting of
/// several segments, in Euclidean space. The segments are parameterized objects constructed by
/// \c LTEuclideanSplineControlPoint objects which represent the control points of the spline, in
/// their given order. The spline is approximately arc-length parameterized, in Euclidean space,
/// according to the \c location of the provided control points. The object is initialized with an
/// ordered collection of control points and a factory for creating spline segments from them. The
/// object can be extended by adding control points. The \c minParametricValue of the spline equals
/// the \c minParametricValue of the first spline segment, while its \c maxParametricValue equals
/// the \c maxParametricValue of the last spline segment. The \c parameterizationKeys of the spline
/// equal the \c propertiesToInterpolate of the control points.
@interface LTMutableEuclideanSpline : NSObject <LTParameterizedObject>

/// Initializes with the given \c factory and the given \c initialControlPoints. The given
/// \c factory is used to create the spline segments constituting the underlying components of this
/// spline. The number of given \c initialControlPoints must be equal or greater than the
/// \c numberOfRequiredInterpolatableObjects of the given \c factory.
- (instancetype)initWithFactory:(LTEuclideanSplineControlPointFactory *)factory
           initialControlPoints:(NSArray<LTEuclideanSplineControlPoint *> *)initialControlPoints;

/// Adds the given \c controlPoints at the end of the ordered collection of control points of this
/// spline, possibly resulting in the creation of one or several spline segments. If the control
/// point addition results in the creation of additional spline segments, the \c splineSegments, the
/// \c minParametricValue and the \c maxParametricValue of this instance are updated accordingly.
/// The given \c controlPoints must be ordered according to increasing \c timestamp values.
///
/// Time complexity: <tt>O(n * m)</tt>, where \c n is the number of given \c controlPoints and \c m
/// is the number of spline segments held by this object.
- (void)pushControlPoints:(NSArray<LTEuclideanSplineControlPoint *> *)controlPoints;

/// Control points constituting this object.
///
/// Time complexity: \c O(n), where \c n is the number of control points held by this object.
@property (readonly, copy, nonatomic) LTEuclideanSplineControlPoints *controlPoints;

/// Parameterized objects constituting the segments of this spline.
///
/// Time complexity: \c O(n), where \c n is the number of spline segments held by this object. The
/// number of spline segments is \c O(1) smaller than the number of control points.
@property (readonly, copy, nonatomic) NSArray<id<LTParameterizedObject>> *segments;

@end

NS_ASSUME_NONNULL_END
