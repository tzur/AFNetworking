// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNPipeline.h"

#import <LTEngine/LTAttributeData.h>
#import <LTEngine/LTContinuousSampler.h>
#import <LTEngine/LTDynamicQuadDrawer.h>
#import <LTEngine/LTRotatedRect.h>
#import <LTEngine/LTSampleValues.h>

#import "DVNAttributeProvider.h"
#import "DVNAttributeStageConfiguration.h"
#import "DVNGeometryProvider.h"
#import "DVNGeometryValues.h"
#import "DVNPipelineConfiguration.h"
#import "DVNRenderStageConfiguration.h"
#import "DVNTexCoordProvider.h"
#import "DVNTextureMappingStageConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVNPipeline ()

/// Object used to sample provided parameterized objects.
@property (readonly, nonatomic) id<LTContinuousSampler> sampler;

/// Object providing quadrilateral geometry, given values sampled from parameterized objects.
@property (readonly, nonatomic) id<DVNGeometryProvider> geometryProvider;

/// Texture used for texture mapping of the rendered quadrilateral geometry.
@property (readonly, nonatomic) LTTexture *texture;

/// Object providing for each vertex of the rendered quadrilaterals the corresponding texture
/// coordinates.
@property (readonly, nonatomic) id<DVNTexCoordProvider> texCoordProvider;

/// Object potentially assigning to each vertex of the rendered quadrilaterals additional
/// attributes.
@property (readonly, nonatomic) NSArray<id<DVNAttributeProvider>> *attributeProviders;

/// Configuration of the render stage.
@property (readonly, nonatomic) DVNRenderStageConfiguration *renderStageConfiguration;

/// Object used to perform the actual rendering.
@property (readonly, nonatomic) LTDynamicQuadDrawer *drawer;

@end

@implementation DVNPipeline

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithConfiguration:(DVNPipelineConfiguration *)configuration {
  LTParameterAssert(configuration);

  if (self = [super init]) {
    _sampler = [configuration.samplingStageConfiguration sampler];
    _geometryProvider = [configuration.geometryStageConfiguration provider];
    _texture = configuration.textureStageConfiguration.texture;
    _texCoordProvider = [configuration.textureStageConfiguration.model provider];
    NSArray<id<DVNAttributeProviderModel>> *attributeProviderModels =
        configuration.attributeStageConfiguration.models;
    _attributeProviders = [self attributeProvidersFromModels:attributeProviderModels];
    NSOrderedSet<LTGPUStruct *> *gpuStructs = [self gpuStructsFromModels:attributeProviderModels];
    _renderStageConfiguration = configuration.renderStageConfiguration;
    _drawer = [[LTDynamicQuadDrawer alloc]
               initWithVertexSource:self.renderStageConfiguration.vertexSource
               fragmentSource:self.renderStageConfiguration.fragmentSource
               gpuStructs:gpuStructs];
  }
  return self;
}

- (NSArray<id<DVNAttributeProvider>> *)
    attributeProvidersFromModels:(NSArray<id<DVNAttributeProviderModel>> *)models {
  NSMutableArray<id<DVNAttributeProvider>> *providers =
      [NSMutableArray arrayWithCapacity:models.count];

  for (id<DVNAttributeProviderModel> model in models) {
    [providers addObject:[model provider]];
  }

  return [providers copy];
}

- (NSOrderedSet<LTGPUStruct *> *)
    gpuStructsFromModels:(NSArray<id<DVNAttributeProviderModel>> *)models {
  NSMutableOrderedSet<LTGPUStruct *> *gpuStructs =
      [NSMutableOrderedSet orderedSetWithCapacity:models.count];

  for (id<DVNAttributeProviderModel> model in models) {
    [gpuStructs addObject:[model sampleAttributeData].gpuStruct];
  }

  return [gpuStructs copy];
}

#pragma mark -
#pragma mark Public Interface - Processing
#pragma mark -

- (void)processParameterizedObject:(id<LTParameterizedObject>)parameterizedObject
                        inInterval:(lt::Interval<CGFloat>)interval end:(BOOL)end {
  if (interval.isEmpty()) {
    return;
  }

  id<LTSampleValues> sampleValues =
      [self.sampler nextSamplesFromParameterizedObject:parameterizedObject
                                 constrainedToInterval:interval];

  if (!sampleValues.mappingOfSampledValues) {
    return;
  }

  const dvn::GeometryValues geometryValues = [self.geometryProvider valuesFromSamples:sampleValues
                                                                                  end:end];
  const std::vector<lt::Quad> &quads = geometryValues.quads();

  [self.drawer drawQuads:quads textureMapQuads:[self.texCoordProvider textureMapQuadsForQuads:quads]
           attributeData:[self attributeDataFromGeometryValues:geometryValues]
                 texture:self.texture auxiliaryTextures:self.auxiliaryTextures
                uniforms:self.uniforms];

  [self.delegate pipeline:self renderedQuads:quads];
}

- (NSArray<LTAttributeData *> *)
    attributeDataFromGeometryValues:(const dvn::GeometryValues &)values {
  NSMutableArray<LTAttributeData *> *data =
      [NSMutableArray arrayWithCapacity:self.attributeProviders.count];

  for (id<DVNAttributeProvider> provider in self.attributeProviders) {
    [data addObject:[provider attributeDataFromGeometryValues:values]];
  }

  return [data copy];
}

#pragma mark -
#pragma mark Public Interface - Configuration
#pragma mark -

- (DVNPipelineConfiguration *)currentConfiguration {
  return [[DVNPipelineConfiguration alloc]
          initWithSamplingStageConfiguration:[self.sampler currentModel]
          geometryStageConfiguration:[self.geometryProvider currentModel]
          textureMappingStageConfiguration:[self currentTextureStageConfiguration]
          attributeStageConfiguration:[self currentAttributeStageConfiguration]
          renderStageConfiguration:self.renderStageConfiguration];
}

- (DVNTextureMappingStageConfiguration *)currentTextureStageConfiguration {
  return [[DVNTextureMappingStageConfiguration alloc]
          initWithTexCoordProviderModel:[self.texCoordProvider currentModel]
          texture:self.texture];
}

- (DVNAttributeStageConfiguration *)currentAttributeStageConfiguration {
  NSMutableArray<id<DVNAttributeProviderModel>> *models =
      [NSMutableArray arrayWithCapacity:self.attributeProviders.count];

  for (id<DVNAttributeProvider> provider in self.attributeProviders) {
    [models addObject:[provider currentModel]];
  }

  return [[DVNAttributeStageConfiguration alloc] initWithAttributeProviderModels:[models copy]];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (NSDictionary<NSString *, LTTexture *> *)auxiliaryTextures {
  return self.renderStageConfiguration.auxiliaryTextures;
}

- (NSDictionary<NSString *, NSValue *> *)uniforms {
  return self.renderStageConfiguration.uniforms;
}

@end

NS_ASSUME_NONNULL_END
