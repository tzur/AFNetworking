// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@protocol LTInterpolatableObject, LTParameterizedObject, LTPrimitiveParameterizedObjectFactory;

/// Factory for creating \c id<LTParameterizedObject> objects constituted by a set of
/// \c id<LTPrimitiveParameterizedObject> objects. The factory is initialized with a factory for
/// creating the primitive parameterized objects and constructs parameterized objects from the
/// interpolatable properties of given \c id<LTInterpolatableObject> objects.
@interface LTParameterizedObjectFactory<__covariant ObjectType:id<LTInterpolatableObject>> :
    NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c factory used to create the primitive parameterized objects
/// constituting the parameterized objects which can be created by this instance.
- (instancetype)initWithPrimitiveFactory:(id<LTPrimitiveParameterizedObjectFactory>)factory
    NS_DESIGNATED_INITIALIZER;

/// Returns a parameterized object mapping each of the interpolatable properties of the given
/// \c objects to a corresponding primitive parameterized object created by the \c primitiveFactory.
/// The number of given \c objects must equal the \c numberOfRequiredInterpolatableObjects.
- (id<LTParameterizedObject>)parameterizedObjectFromInterpolatableObjects:
    (NSArray<ObjectType> *)objects;

/// Returns the number of interpolatable objects required to create a corresponding parameterized
/// object.
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
- (NSRange)intrinsicParametricRange;

@end

NS_ASSUME_NONNULL_END
