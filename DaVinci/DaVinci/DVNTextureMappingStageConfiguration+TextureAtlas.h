// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNTextureMappingStageConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@class LTTextureAtlas;

/// Category augmenting the \c DVNTextureMappingStageConfiguration class with convenience
/// functionality to create a configuration of the texture mapping stage of the \c DVNPipeline using
/// a texture atlas.
@interface DVNTextureMappingStageConfiguration (TextureAtlas)

/// Returns a new \c DVNTextureMappingStageConfiguration using the texture of the given
/// \c textureAtlas and a \c DVNRandomTexCoordProviderModel as \c model. The \c randomState of the
/// \c DVNRandomTexCoordProviderModel is random and the \c textureMapQuads are constructed from the
/// \c areas of the given \c textureAtlas.
+ (instancetype)configurationFromTextureAtlas:(LTTextureAtlas *)textureAtlas;

@end

NS_ASSUME_NONNULL_END
