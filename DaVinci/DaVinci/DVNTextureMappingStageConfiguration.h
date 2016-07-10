// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

@protocol DVNTexCoordProviderModel;

/// Immutable object representing the configuration of the texture mapping stage of the
/// \c DVNPipeline.
@interface DVNTextureMappingStageConfiguration : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c texCoordProviderModel used for providing texture coordinates and
/// the given \c texture used for texture mapping.
- (instancetype)initWithTexCoordProviderModel:(id<DVNTexCoordProviderModel>)texCoordProviderModel
                                      texture:(LTTexture *)texture
    NS_DESIGNATED_INITIALIZER;

/// Model for creating the provider of texture coordinates used for texture mapping.
@property (readonly, nonatomic) id<DVNTexCoordProviderModel> texCoordProviderModel;

/// Texture to be used for texture mapping.
@property (readonly, nonatomic) LTTexture *texture;

@end

NS_ASSUME_NONNULL_END
