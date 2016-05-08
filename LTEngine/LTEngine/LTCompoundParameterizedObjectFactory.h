// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTCompoundParameterizedObject;

@protocol LTInterpolatableObject, LTBasicParameterizedObjectFactory;

/// Factory for creating \c LTCompoundParameterizedObject objects constituted by a set of
/// \c id<LTBasicParameterizedObject> objects. The factory is initialized with a factory for creating
/// the basic parameterized objects and constructs parameterized objects from the interpolatable
/// properties of given \c id<LTInterpolatableObject> objects.
@interface LTCompoundParameterizedObjectFactory<__covariant ObjectType:id<LTInterpolatableObject>> :
    NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c factory used to create the basic parameterized objects
/// constituting the parameterized objects which can be created by this instance.
- (instancetype)initWithBasicFactory:(id<LTBasicParameterizedObjectFactory>)factory
    NS_DESIGNATED_INITIALIZER;

/// Returns a parameterized object mapping each of the interpolatable properties of the given
/// \c objects to a corresponding basic parameterized object created by the \c factory provided
/// upon initialization. The number of given \c objects must equal the
/// \c numberOfRequiredInterpolatableObjects.
- (LTCompoundParameterizedObject *)parameterizedObjectFromInterpolatableObjects:
    (NSArray<ObjectType> *)objects;

/// Returns the number of interpolatable objects required to create a corresponding parameterized
/// object. Returned number is positive.
- (NSUInteger)numberOfRequiredInterpolatableObjects;

/// Returns the range, in terms of the \c objects provided to the
/// \c parameterizedObjectFromInterpolatableObjects: method, representing the intrinsic parametric
/// range of the parameterized object, \c p, created by the method. In particular,
/// @code
/// [p mappingForParametricValue:p.minParametricValue]
/// @endcode
/// returns the mapping from the \c propertiesToInterpolate of
/// \c objects[intrinsicParametricRange.location] to its values. Analogously,
/// @code
/// [p mappingForParametricValue:p.maxParametricValue]
/// @endcode
/// returns the mapping from the \c propertiesToInterpolate of
/// \c objects[intrinsicParametricRange.location+intrinsicParametricRange.length-1] to its values.
///
/// The \c length of the returned range is greater than \c 0. The sum of the \c location and the
/// \c length of the returned range are smaller than or equal to \c numberOfRequiredValues.
- (NSRange)intrinsicParametricRange;

@end

NS_ASSUME_NONNULL_END
