// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNMaskBrushConfigurationProvider.h"

#import <LTEngine/LTTexture+Factory.h>

#import "DVNAttributeStageConfiguration.h"
#import "DVNCanonicalTexCoordProvider.h"
#import "DVNMaskBrushParametersProvider.h"
#import "DVNPatternSamplingStageModel.h"
#import "DVNPipelineConfiguration.h"
#import "DVNQuadAttributeProvider.h"
#import "DVNRenderStageConfiguration.h"
#import "DVNSquareProvider.h"
#import "DVNTextureMappingStageConfiguration.h"
#import "LTShaderStorage+DVNMaskBrushFsh.h"
#import "LTShaderStorage+DVNMaskBrushVsh.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVNMaskBrushConfigurationProvider ()

/// Provider of mask brush parameters, used to create pipeline configurations.
@property (weak, nonatomic) id<DVNMaskBrushParametersProvider> provider;

/// Texture mapping stage configuration of the pipeline configurations returned by this instance.
@property (readonly, nonatomic)
    DVNTextureMappingStageConfiguration *textureMappingStageConfiguration;

/// Attribute stage configuration of the pipeline configurations returned by this instance.
@property (readonly, nonatomic) DVNAttributeStageConfiguration *attributeStageConfiguration;

/// Sampling stage model of the pipeline configurations returned by this instance.
@property (readonly, nonatomic) DVNPatternSamplingStageModel *samplingStageModel;

@end

@implementation DVNMaskBrushConfigurationProvider

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithProvider:(id<DVNMaskBrushParametersProvider>)provider {
  LTParameterAssert(provider);
  
  if (self = [super init]) {
    _provider = provider;
    _samplingStageModel = [self createSamplingStageModel];
    _textureMappingStageConfiguration = [self createTextureMappingStageConfiguration];
    _attributeStageConfiguration = [self createAttributeStageConfiguration];
  }
  return self;
}

- (DVNPatternSamplingStageModel *)createSamplingStageModel {
  DVNPatternSamplingStageModel *samplingStageModel = [[DVNPatternSamplingStageModel alloc] init];
  samplingStageModel.numberOfSamplesPerSequence = 1;
  return samplingStageModel;
}

- (DVNTextureMappingStageConfiguration *)createTextureMappingStageConfiguration {
  DVNCanonicalTexCoordProviderModel *model = [[DVNCanonicalTexCoordProviderModel alloc] init];
  
  // Provide dummy texture due to the fact that the \c DVNMaskBrush fragment shader computes the
  // necessary Gaussian by itself.
  LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
  return [[DVNTextureMappingStageConfiguration alloc] initWithTexCoordProviderModel:model
                                                                            texture:texture];
}

- (DVNAttributeStageConfiguration *)createAttributeStageConfiguration {
  return [[DVNAttributeStageConfiguration alloc]
          initWithAttributeProviderModels:@[[[DVNQuadAttributeProviderModel alloc] init]]];
}

#pragma mark -
#pragma mark Public API
#pragma mark -

- (DVNPipelineConfiguration *)configuration {
  CGFloat spacing = self.provider.spacing;
  self.samplingStageModel.spacing = spacing;
  self.samplingStageModel.sequenceDistance = spacing;
  
  return [[DVNPipelineConfiguration alloc]
          initWithSamplingStageConfiguration:[self.samplingStageModel continuousSamplerModel]
          geometryStageConfiguration:[self createSquareProviderModel]
          textureMappingStageConfiguration:self.textureMappingStageConfiguration
          attributeStageConfiguration:self.attributeStageConfiguration
          renderStageConfiguration:[self createRenderStageConfiguration]];
}

- (DVNSquareProviderModel *)createSquareProviderModel {
  return [[DVNSquareProviderModel alloc] initWithEdgeLength:self.provider.diameter];
}

- (DVNRenderStageConfiguration *)createRenderStageConfiguration {
  NSDictionary<NSString *, LTTexture *> *auxiliaryTextures = @{
    [DVNMaskBrushFsh edgeAvoidanceGuideTexture]: self.provider.edgeAvoidanceGuideTexture
  };
  NSDictionary<NSString *, NSValue *> *uniforms = @{
    [DVNMaskBrushFsh channel]: @(self.provider.channel),
    [DVNMaskBrushFsh mode]: @(self.provider.mode),
    [DVNMaskBrushFsh flow]: @(self.provider.flow),
    [DVNMaskBrushFsh hardness]: @(self.provider.hardness),
    [DVNMaskBrushFsh edgeAvoidance]: @(self.provider.edgeAvoidance)
  };
  
  return [[DVNRenderStageConfiguration alloc] initWithVertexSource:[DVNMaskBrushVsh source]
                                                    fragmentSource:[DVNMaskBrushFsh source]
                                                 auxiliaryTextures:auxiliaryTextures
                                                          uniforms:uniforms];
}

- (nullable id<DVNMaskBrushParametersProvider>)provider {
  LTAssert(_provider, @"Provider has been deallocated before this object was deallocated");
  return _provider;
}

@end

NS_ASSUME_NONNULL_END
