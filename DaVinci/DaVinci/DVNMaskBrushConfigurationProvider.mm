// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNMaskBrushConfigurationProvider.h"

#import <LTEngine/LTTexture+Factory.h>

#import "DVNAttributeStageConfiguration.h"
#import "DVNBrushTipsProvider.h"
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

const CGFloat kMaskBrushDimension = 256;

@interface DVNMaskBrushConfigurationProvider ()

/// Provider of mask brush parameters, used to create pipeline configurations.
@property (weak, nonatomic) id<DVNMaskBrushParametersProvider> parametersProvider;

/// Provider of brush tips, used to create mask brush tip textures.
@property (readonly, nonatomic) DVNBrushTipsProvider *brushTipsProvider;

/// Attribute stage configuration of the pipeline configurations returned by this instance.
@property (readonly, nonatomic) DVNAttributeStageConfiguration *attributeStageConfiguration;

/// Sampling stage model of the pipeline configurations returned by this instance.
@property (readonly, nonatomic) DVNPatternSamplingStageModel *samplingStageModel;

@end

@implementation DVNMaskBrushConfigurationProvider

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithParametersProvider:(id<DVNMaskBrushParametersProvider>)parametersProvider
                         brushTipsProvider:(DVNBrushTipsProvider *)brushTipsProvider {
  LTParameterAssert(parametersProvider);
  LTParameterAssert(brushTipsProvider);
  
  if (self = [super init]) {
    _parametersProvider = parametersProvider;
    _brushTipsProvider = brushTipsProvider;
    _samplingStageModel = [self createSamplingStageModel];
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
  LTTexture *texture = (LTTexture *)[self.brushTipsProvider
                                     roundTipWithDimension:kMaskBrushDimension
                                     hardness:self.parametersProvider.hardness];
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
  CGFloat spacing = self.parametersProvider.spacing;
  self.samplingStageModel.spacing = spacing;
  self.samplingStageModel.sequenceDistance = spacing;
  
  return [[DVNPipelineConfiguration alloc]
          initWithSamplingStageConfiguration:[self.samplingStageModel continuousSamplerModel]
          geometryStageConfiguration:[self createSquareProviderModel]
          textureMappingStageConfiguration:[self createTextureMappingStageConfiguration]
          attributeStageConfiguration:self.attributeStageConfiguration
          renderStageConfiguration:[self createRenderStageConfiguration]];
}

- (DVNSquareProviderModel *)createSquareProviderModel {
  return [[DVNSquareProviderModel alloc] initWithEdgeLength:self.parametersProvider.diameter];
}

- (DVNRenderStageConfiguration *)createRenderStageConfiguration {
  NSDictionary<NSString *, LTTexture *> *auxiliaryTextures = @{
    [DVNMaskBrushFsh edgeAvoidanceGuideTexture]: self.parametersProvider.edgeAvoidanceGuideTexture
  };
  NSDictionary<NSString *, NSValue *> *uniforms = @{
    [DVNMaskBrushFsh channel]: @(self.parametersProvider.channel),
    [DVNMaskBrushFsh mode]: @(self.parametersProvider.mode),
    [DVNMaskBrushFsh flow]: @(self.parametersProvider.flow),
    [DVNMaskBrushFsh edgeAvoidance]: @(self.parametersProvider.edgeAvoidance)
  };
  
  return [[DVNRenderStageConfiguration alloc] initWithVertexSource:[DVNMaskBrushVsh source]
                                                    fragmentSource:[DVNMaskBrushFsh source]
                                                 auxiliaryTextures:auxiliaryTextures
                                                          uniforms:uniforms];
}

- (nullable id<DVNMaskBrushParametersProvider>)parametersProvider {
  LTAssert(_parametersProvider,
           @"Provider has been deallocated before this object was deallocated");
  return _parametersProvider;
}

@end

NS_ASSUME_NONNULL_END
