// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObject.h"

NS_ASSUME_NONNULL_BEGIN

@class LTControlPointModel, LTEuclideanSplineControlPoint;

/// Mutable object responsible for constructing and iteratively extending an
/// \c LTParameterizedObject using a given \c LTControlPointModel, specifying the type of the
/// factory for basic parameterized objects and a possibly existing ordered collection of initial
/// Euclidean spline control points. The object has two states: in its initial state the object does
/// not provide any parameterized object. In its second state, reachable through the initial state,
/// it does provide a parameterized object. The transition occurs when the total number of control
/// points iteratively provided to the object reaches the \c numberOfRequiredValues of the
/// aforementioned factory. Once a parameterized object has been constructed, additional incoming
/// control points are used to extend it according to aforementioned factory. Changes of the
/// parameterized object of an instance are guaranteed to occur exclusively and immediately as a
/// result of a) its initialization and b) calls to the \c pushControlPoints: method.
@interface LTParameterizedObjectConstructor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c model.
- (instancetype)initWithControlPointModel:(LTControlPointModel *)model NS_DESIGNATED_INITIALIZER;

/// Adds the given \c control points.
- (void)pushControlPoints:(NSArray<LTEuclideanSplineControlPoint *> *)controlPoints;

/// Model representing the current \c parameterizedObject.
- (LTControlPointModel *)controlPointModel;

/// Iteratively constructed parameterized object. Is \c nil as long as the total number of control
/// points provided to this object is smaller than the \c numberOfRequiredValues of the factory
/// whose type was provided upon initialization.
///
/// @note The returned parameterized object constitutes an arc-length parameterized spline
/// interpolating the control points of this instance according to the factory of the type provided
/// upon initialization.
///
/// @important The returned parameterized object should not be stored since it might be modified by
/// this object in the future.
@property (readonly, nonatomic, nullable) id<LTParameterizedObject>parameterizedObject;

@end

NS_ASSUME_NONNULL_END
