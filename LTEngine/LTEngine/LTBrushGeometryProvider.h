// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTEuclideanSplineControlPoint, LTRotatedRect;

@protocol LTBrushGeometryProviderModel, LTParameterizedObject;

/// Protocol which should be implemented by objects providing geometry from samples of a given
/// parameterized object or from a single Euclidean spline control point. The objects support
/// geometry providing in an iterative way which causes them to be intrinsically stateful. To ensure
/// an immutable representation of the object state, each object has an immutable model associated
/// with it from which the object can be created and which can be created from the current state of
/// an object.
@protocol LTBrushGeometryProvider <NSObject>

/// The default initializer is disabled since providers should be created solely using their
/// associated models.
- (instancetype)init NS_UNAVAILABLE;

/// Returns an ordered collection of rotated rects representing geometry constructed from samples,
/// at the given \c parametricValues, of the given parameterized \c object.
- (NSArray<LTRotatedRect *> *)rotatedRectsFromParameterizedObject:(id<LTParameterizedObject>)object
                                               atParametricValues:(CGFloats)parametricValues;

/// Returns a single rotated rect representing geometry constructed from the given \c point.
- (LTRotatedRect *)rotatedRectFromControlPoint:(LTEuclideanSplineControlPoint *)point;

/// Returns an immutable model representing the current state of this object.
- (id<LTBrushGeometryProviderModel>)currentModel;

@end

/// Protocol which should be implemented by immutable value classes representing the model from
/// which an associated \c id<LTBrushGeometryProvider> can be created.
@protocol LTBrushGeometryProviderModel <NSObject, NSCopying>

/// Creates a new geometry provider.
- (id<LTBrushGeometryProvider>)provider;

@end

NS_ASSUME_NONNULL_END
