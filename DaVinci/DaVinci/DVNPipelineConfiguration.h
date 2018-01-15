// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class DVNAttributeStageConfiguration, DVNRenderStageConfiguration,
    DVNTextureMappingStageConfiguration;

@protocol DVNGeometryProviderModel, LTContinuousSamplerModel;

/// Value object to be used as configuration of \c DVNPipeline objects. The components of a
/// \c DVNPipeline initialized with this object are constructed from the models provided by this
/// object.
@interface DVNPipelineConfiguration : NSObject

/// Initializes with the given \c samplingConfiguration, \c geometryConfiguration,
/// \c textureConfiguration, \c attributeConfiguration and \c renderConfiguration.
- (instancetype)
    initWithSamplingStageConfiguration:(id<LTContinuousSamplerModel>)samplingConfiguration
    geometryStageConfiguration:(id<DVNGeometryProviderModel>)geometryConfiguration
    textureMappingStageConfiguration:(DVNTextureMappingStageConfiguration *)textureConfiguration
    attributeStageConfiguration:(DVNAttributeStageConfiguration *)attributeConfiguration
    renderStageConfiguration:(DVNRenderStageConfiguration *)renderConfiguration;

/// Returns a new instance whose properties are identical to those of the receiver, with the
/// exception of the given render stage \c configuration.
- (instancetype)
    shallowCopyWithRenderStageConfiguration:(DVNRenderStageConfiguration *)configuration;

/// Configuration of the sampling stage of a \c DVNPipeline object.
@property (readonly, nonatomic) id<LTContinuousSamplerModel> samplingStageConfiguration;

/// Configuration of the geometry stage of a \c DVNPipeline object.
@property (readonly, nonatomic) id<DVNGeometryProviderModel> geometryStageConfiguration;

/// Configuration of the texture mapping stage of a \c DVNPipeline object.
@property (readonly, nonatomic) DVNTextureMappingStageConfiguration *textureStageConfiguration;

/// Configuration of the attribute stage of a \c DVNPipeline object.
@property (readonly, nonatomic) DVNAttributeStageConfiguration *attributeStageConfiguration;

/// Configuration of the attribute stage of a \c DVNPipeline object.
@property (readonly, nonatomic) DVNRenderStageConfiguration *renderStageConfiguration;

@end

NS_ASSUME_NONNULL_END
