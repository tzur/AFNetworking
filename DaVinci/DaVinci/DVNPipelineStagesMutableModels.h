// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import <LTEngine/LTJSONSerializationAdapter.h>
#import <Mantle/MTLModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LTContinuousSamplerModel, DVNGeometryProviderModel;

@class DVNTextureMappingStageConfiguration, DVNAttributeStageConfiguration,
    DVNRenderStageConfiguration;

/// Protocol to be implemented by mutable serializable models that provide
/// \c id<LTContinuousSamplerModel> objects for the sampling stage of the \c DVNPipeline.
@protocol DVNSamplingStageModel <LTJSONSerializing, MTLJSONSerializing>

/// Returns a continuous sampler model derived from the current state of this instance.
- (id<LTContinuousSamplerModel>)continuousSamplerModel;

@end

/// Protocol to be implemented by mutable serializable models that provide
/// \c id<DVNGeometryProviderModel> objects for the geometry stage of the \c DVNPipeline.
@protocol DVNGeometryStageModel <LTJSONSerializing, MTLJSONSerializing>

/// Returns a geometry provider model derived from the current state of this instance.
- (id<DVNGeometryProviderModel>)geometryProviderModel;

@end

/// Protocol to be implemented by mutable serializable models that provide
/// \c id<DVNTextureMappingStageConfiguration> objects for the texture mapping stage of the
/// \c DVNPipeline.
@protocol DVNTextureMappingStageModel <LTJSONSerializing, MTLJSONSerializing>

/// Returns a texture mapping stage configuration derived from the current state of this instance.
- (DVNTextureMappingStageConfiguration *)textureMappingStageConfiguration;

@end

/// Protocol to be implemented by mutable serializable models that provide
/// \c id<DVNAttributeStageConfiguration> objects for the attribute stage of the \c DVNPipeline.
@protocol DVNAttributeStageModel <LTJSONSerializing, MTLJSONSerializing>

/// Returns a attribute stage configuration derived from the current state of this instance.
- (DVNAttributeStageConfiguration *)attributeStageConfiguration;

@end

/// Protocol to be implemented by mutable serializable models that provide
/// \c id<DVNRenderStageConfiguration> objects for the rendering stage of the \c DVNPipeline.
@protocol DVNRenderStageModel <LTJSONSerializing, MTLJSONSerializing>

/// Returns a render stage configuration derived from the current state of this instance.
- (DVNRenderStageConfiguration *)renderStageConfiguration;

@end

NS_ASSUME_NONNULL_END
