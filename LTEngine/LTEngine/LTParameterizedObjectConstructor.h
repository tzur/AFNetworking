// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObject.h"

NS_ASSUME_NONNULL_BEGIN

@class LTControlPointModel, LTParameterizedObjectType, LTSplineControlPoint;

/// Mutable object responsible for constructing and iteratively extending an
/// \c LTParameterizedObject using a given \c LTParameterizedObjectType, determining the factory
/// used for constructing the basic parameterized objects making up the \c LTParameterizedObject,
/// and an ordered collection of Euclidean spline control points, provided consecutively. The object
/// has two states: in its initial state the object does not provide any parameterized object. In
/// its second state, reachable through the initial state, it does provide a parameterized object.
/// The transition occurs when the total number of control points iteratively provided to the object
/// reaches the \c numberOfRequiredValues of the aforementioned factory. Once a parameterized object
/// has been constructed, additional incoming control points are used to extend it according to
/// aforementioned factory. Changes of the parameterized object of an instance are guaranteed to
/// occur exclusively and immediately as a result of calls to the \c pushControlPoints: method.
///
/// The object can be reset to its initial state by calling the \c reset method.
@interface LTParameterizedObjectConstructor : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c type determining the factory used for constructing the basic
/// parameterized objects making up the \c parameterizedObject.
- (instancetype)initWithType:(LTParameterizedObjectType *)type NS_DESIGNATED_INITIALIZER;

/// Adds the given \c control points, possibly creating/extending the \c parameterizedObject.
- (void)pushControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints;

/// Removes the \c numberOfControlPoints last control points, shortening or possibly removing the
/// \c parameterizedObject.
- (void)popControlPoints:(NSUInteger)numberOfControlPoints;

/// Resets the instance to its initial state. Returns the model representing the
/// \c parameterizedObject held right before the call to this method.
- (LTControlPointModel *)reset;

/// Returns a parameterized object represented by the given \c model, or \c nil if the number of
/// control points of the given \c model is smaller than the \c numberOfRequiredValues of the
/// factory described by the \c type of the given \c model.
+ (nullable id<LTParameterizedObject>)parameterizedObjectFromModel:(LTControlPointModel *)model;

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

/// Type of the factory used for spline construction.
@property (readonly, nonatomic) LTParameterizedObjectType *type;

@end

NS_ASSUME_NONNULL_END
