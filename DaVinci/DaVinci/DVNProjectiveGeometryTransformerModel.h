// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNGeometryProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Model of a geometry provider first delegating the geometry creation to another provider,
/// afterwards iterating over the constructed quads, transforming each quad according to a fixed
/// \c GLKMatrix3, and finally returning the transformed quads.
@interface DVNProjectiveGeometryTransformerModel : NSObject <DVNGeometryProviderModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initialized with the given \c model of another geometry provider and the given \c transform. The
/// quads provided by a geometry provider constructed from the returned instance are the quads of
/// the geometry provider created from the given \c model, transformed according to the given
/// \c transform.
- (instancetype)initWithGeometryProviderModel:(id<DVNGeometryProviderModel>)model
                                    transform:(GLKMatrix3)transform
    NS_DESIGNATED_INITIALIZER;

/// Model of geometry provider used to retrieve quads.
@property (readonly, nonatomic) id<DVNGeometryProviderModel> model;

/// Transform applied to all quads retrieved from the geometry provider constructed from the
/// \c model of this instance.
@property (readonly, nonatomic) GLKMatrix3 transform;

@end

NS_ASSUME_NONNULL_END
