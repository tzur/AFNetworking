// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTQuad.h>

#import "DVNGeometryValues.h"

NS_ASSUME_NONNULL_BEGIN

@class LTAttributeData, LTGPUStruct;

@protocol DVNAttributeProviderModel;

/// Protocol which should be implemented by objects providing additional attributes for given
/// quadrilateral geometry. The implementing objects might be stateful. To ensure an immutable
/// representation of the object state, each object has an immutable model associated with it from
/// which the object can be created or which can be created from the current state of an object.
@protocol DVNAttributeProvider <NSObject>

/// The default initializer is disabled since providers should be created solely using their
/// associated models.
- (instancetype)init NS_UNAVAILABLE;

/// Returns attribute data to be associated with the \c quads of the given \c values. The returned
/// attribute data is formatted for draw calls with the \c LTDrawingContextDrawModeTriangles
/// setting, with vertex order <tt>(v0, v1, v2, v0, v2, v3)</tt> per quad.
- (LTAttributeData *)attributeDataFromGeometryValues:(dvn::GeometryValues)values;

/// Returns an immutable model representing the current state of this object.
- (id<DVNAttributeProviderModel>)currentModel;

@end

/// Protocol which should be implemented by immutable value classes representing the model from
/// which an associated \c id<DVNAttributeProvider> can be created.
@protocol DVNAttributeProviderModel <NSObject, NSCopying>

/// Returns an attribute provider with the state represented by this instance.
- (id<DVNAttributeProvider>)provider;

/// Empty attribute data object indicating the structure of any \c LTAttributeData object returned
/// by the provider which can be constructed from this instance.
- (LTAttributeData *)sampleAttributeData;

@end

NS_ASSUME_NONNULL_END
