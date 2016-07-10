// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTQuad.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVNTexCoordProviderModel;

/// Protocol which should be implemented by objects providing texture coordinates for given
/// quadrilateral geometry. The implementing objects might be stateful. To ensure an immutable
/// representation of the object state, each object has an immutable model associated with it from
/// which the object can be created or which can be created from the current state of an object.
@protocol DVNTexCoordProvider <NSObject>

/// The default initializer is disabled since providers should be created solely using their
/// associated models.
- (instancetype)init NS_UNAVAILABLE;

/// Returns an ordered collection of quads, in normalized coordinates, determining the quadrilateral
/// regions in a texture to use for texture mapping of the given \c quads. In particular, the number
/// of returned quads equals the number of given \c quads.
- (std::vector<lt::Quad>)textureMapQuadsForQuads:(const std::vector<lt::Quad> &)quads;

/// Returns an immutable model representing the current state of this object.
- (id<DVNTexCoordProviderModel>)currentModel;

@end

/// Protocol which should be implemented by immutable value classes representing the model from
/// which an associated \c id<DVNTexCoordProvider> can be created.
@protocol DVNTexCoordProviderModel <NSObject, NSCopying>

/// Returns a texture coordinate provider with the state represented by this instance.
- (id<DVNTexCoordProvider>)provider;

@end

NS_ASSUME_NONNULL_END
