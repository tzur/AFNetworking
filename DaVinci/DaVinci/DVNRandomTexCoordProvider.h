// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNTexCoordProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class LTRandomState;

/// Model of an \c id<DVNTexCoordProvider> object providing quads randomly chosen from a collection
/// of quads, given in units of the \c UV texture coordinate system.
@interface DVNRandomTexCoordProviderModel : NSObject <DVNTexCoordProviderModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c randomState and the given \c textureMapQuads from which quads can
/// randomly be chosen. The \c textureMapQuads must contain at least one quad and are assumed to be
/// in units of the \c UV texture coordinate system.
- (instancetype)initWithRandomState:(LTRandomState *)randomState
                    textureMapQuads:(const std::vector<lt::Quad> &)textureMapQuads
    NS_DESIGNATED_INITIALIZER;

/// State of the random number generator.
@property (readonly, nonatomic) LTRandomState *randomState;

/// Collection of quads from which quads for texture mapping can be chosen.
@property (readonly, nonatomic) std::vector<lt::Quad> textureMapQuads;

@end

NS_ASSUME_NONNULL_END
