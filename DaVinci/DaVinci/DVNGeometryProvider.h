// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNGeometryValues.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVNGeometryProviderModel, LTSampleValues;

/// Protocol which should be implemented by objects providing quadrilateral geometry for given
/// \c LTSampleValues. The implementing objects might be stateful. To ensure an immutable
/// representation of the object state, each object has an immutable model associated with it from
/// which the object can be created or which can be created from the current state of an object.
@protocol DVNGeometryProvider <NSObject>

/// The default initializer is disabled since providers should be created solely using their
/// associated models.
- (instancetype)init NS_UNAVAILABLE;

/// Returns quadrilateral geometry constructed from the given \c samples. The \c end indication
/// should be set to \c YES in order to indicate the end of a consecutively provided sample
/// sequence.
///
/// @important The \c samples() of the returned \c dvn::GeometryValues may be different from the
/// given \c samples, e.g. in case in which the receiver performs buffering, and, hence, must
/// consecutively be used rather than the given \c samples.
- (dvn::GeometryValues)valuesFromSamples:(id<LTSampleValues>)samples end:(BOOL)end;

/// Returns an immutable model representing the current state of this object.
- (id<DVNGeometryProviderModel>)currentModel;

@end

/// Protocol which should be implemented by immutable value classes representing the model from
/// which an associated \c id<DVNGeometryProvider> can be created.
@protocol DVNGeometryProviderModel <NSObject, NSCopying>

/// Returns a quadrilateral geometry provider with the state represented by this instance.
- (id<DVNGeometryProvider>)provider;

@end

NS_ASSUME_NONNULL_END
