// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObject.h"
#import "LTSplineControlPoint.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTInterpolatableObject;

@class LTCompoundParameterizedObjectFactory<ObjectType:id<LTInterpolatableObject>>;

/// Factory constructing compound parameterized objects from \c LTSplineControlPoint objects.
typedef LTCompoundParameterizedObjectFactory<LTSplineControlPoint *> LTSplineControlPointFactory;

/// Mutable, univariately parameterized object constituting an extensible spline consisting of
/// several segments, in Euclidean space. The segments are parameterized objects constructed by
/// \c LTSplineControlPoint objects which represent the control points of the spline, in their given
/// order. The spline is approximately arc-length parameterized, in Euclidean space, according to
/// the \c location of the provided control points. The object is initialized with an ordered
/// collection of control points and a factory for creating spline segments from them. The object
/// can be extended by adding control points. The \c minParametricValue of the spline equals the
/// \c minParametricValue of the first spline segment, while its \c maxParametricValue equals the
/// \c maxParametricValue of the last spline segment. The \c parameterizationKeys of the spline
/// equal the \c propertiesToInterpolate of the control points.
@interface LTMutableEuclideanSpline : NSObject <LTParameterizedObject>

/// Initializes with the given \c factory and the given \c initialControlPoints. The given
/// \c factory is used to create the spline segments constituting the underlying components of this
/// spline. The number of given \c initialControlPoints must be equal or greater than the
/// \c numberOfRequiredInterpolatableObjects of the given \c factory.
- (instancetype)initWithFactory:(LTSplineControlPointFactory *)factory
           initialControlPoints:(NSArray<LTSplineControlPoint *> *)initialControlPoints;

/// Adds the given \c controlPoints at the end of the ordered collection of control points of this
/// spline, possibly resulting in the creation of one or several spline segments. If the control
/// point addition results in the creation of additional spline segments, the \c segments and the
/// \c maxParametricValue of this instance are updated accordingly. The given \c controlPoints must
/// be ordered according to increasing \c timestamp values.
///
/// Time complexity: <tt>O(n * m)</tt>, where \c n is the number of given \c controlPoints and \c m
/// is the number of spline segments held by this object.
- (void)pushControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints;

/// Removes the \c numberOfControlPoints last control points from the ordered collection of control
/// points of this spline, possibly resulting in the removal of one or several spline segments. If
/// the control point removal results in the removal of spline segments, the \c segments and the
/// \c maxParametricValue of this instance are updated accordingly.
///
/// @important If the given \c numberOfControlPoints exceeds the number of control points which can
/// be popped without removal of the very first spline segment, only the minimum of the two numbers
/// is used. In other words, the first spline segment is never removed. This is in order to avoid
/// degenerate spline objects.
///
/// Time complexity: <tt>O(n * m)</tt>, where \c n is \c numberOfControlPoints and \c m is the
/// number of spline segments held by this object.
- (void)popControlPoints:(NSUInteger)numberOfControlPoints;

/// Control points constituting this object.
///
/// Time complexity: \c O(n), where \c n is the number of control points held by this object. The
///                  time complexity is linear since a copy of the underlying container is returned.
///
/// @important For retrieval of the \c count of this array, use the \c numberOfControlPoints
/// property.
@property (readonly, copy, nonatomic) NSArray<LTSplineControlPoint *> *controlPoints;

/// Number of control points constituting this object.
///
/// Time complexity: \c O(1).
@property (readonly, nonatomic) NSUInteger numberOfControlPoints;

/// Parameterized objects constituting the segments of this spline.
///
/// Time complexity: \c O(n), where \c n is the number of spline segments held by this object. The
///                  number of spline segments is \c O(1) smaller than the number of control points.
///                  The time complexity is linear since a copy of the underlying container is
///                  returned.
///
/// @important For retrieval of the \c count of this array, use the \c numberOfSegments
/// property.
@property (readonly, nonatomic) NSArray<id<LTParameterizedObject>> *segments;

/// Number of parameterized object constituting the segments of this object.
///
/// Time complexity: \c O(1).
@property (readonly, nonatomic) NSUInteger numberOfSegments;

@end

NS_ASSUME_NONNULL_END
