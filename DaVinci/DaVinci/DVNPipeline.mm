// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNPipeline.h"

#import <LTEngine/LTAttributeData.h>
#import <LTEngine/LTContinuousSampler.h>
#import <LTEngine/LTDynamicQuadDrawer.h>
#import <LTEngine/LTGPUStruct.h>
#import <LTEngine/LTRotatedRect.h>
#import <LTEngine/LTSampleValues.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKit/NSString+Hashing.h>

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
@property (strong, nonatomic) id<LTContinuousSampler> sampler;

/// Object providing quadrilateral geometry, given values sampled from parameterized objects.
@property (strong, nonatomic) id<DVNGeometryProvider> geometryProvider;

/// Texture used for texture mapping of the rendered quadrilateral geometry.
@property (strong, nonatomic) LTTexture *texture;

/// Object providing for each vertex of the rendered quadrilaterals the corresponding texture
/// coordinates.
@property (strong, nonatomic) id<DVNTexCoordProvider> texCoordProvider;

/// Object potentially assigning to each vertex of the rendered quadrilaterals additional
/// attributes.
@property (strong, nonatomic) NSArray<id<DVNAttributeProvider>> *attributeProviders;

/// Configuration of the render stage.
@property (strong, nonatomic) DVNRenderStageConfiguration *renderStageConfiguration;

/// Object used to perform the actual rendering.
@property (strong, nonatomic) LTDynamicQuadDrawer *drawer;

@end

@implementation DVNPipeline

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithConfiguration:(DVNPipelineConfiguration *)configuration {
  LTParameterAssert(configuration);

  if (self = [super init]) {
    [self setConfiguration:configuration];
  }
  return self;
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
  return [self.attributeProviders lt_map:^LTAttributeData *(id<DVNAttributeProvider> provider) {
    return [provider attributeDataFromGeometryValues:values];
  }];
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
  auto models = [self.attributeProviders
                 lt_map:^id<DVNAttributeProviderModel>(id<DVNAttributeProvider> provider) {
    return [provider currentModel];
  }];
  return [[DVNAttributeStageConfiguration alloc] initWithAttributeProviderModels:models];
}

- (void)setConfiguration:(DVNPipelineConfiguration *)configuration {
  self.sampler = [configuration.samplingStageConfiguration sampler];
  self.geometryProvider = [configuration.geometryStageConfiguration provider];
  self.texture = configuration.textureStageConfiguration.texture;
  self.texCoordProvider = [configuration.textureStageConfiguration.model provider];
  NSArray<id<DVNAttributeProviderModel>> *attributeProviderModels =
      configuration.attributeStageConfiguration.models;
  self.attributeProviders = [self attributeProvidersFromModels:attributeProviderModels];
  NSOrderedSet<LTGPUStruct *> *gpuStructs = [self gpuStructsFromModels:attributeProviderModels];
  self.renderStageConfiguration = configuration.renderStageConfiguration;

  if (!self.drawer) {
    self.drawer = [self drawerWithGPUStructs:gpuStructs];
  } else {
    NSString *sourceIdentifier =
        [[self.renderStageConfiguration.vertexSource lt_SHA1]
         stringByAppendingString:[self.renderStageConfiguration.fragmentSource lt_SHA1]];
    BOOL equalParameters = [self.drawer.sourceIdentifier isEqualToString:sourceIdentifier] &&
        [self.drawer.initialGPUStructs isEqual:gpuStructs];

    if (equalParameters) {
      return;
    }

    LogDebug(@"Using configuration with different vertex source and/or fragment source or GPU "
             "structs. If switching between configurations with different source code or GPU "
             "structs occurs frequently, consider allocating separate DVNPipeline instances.");
    self.drawer = [self drawerWithGPUStructs:gpuStructs];
  }
}

- (NSArray<id<DVNAttributeProvider>> *)
    attributeProvidersFromModels:(NSArray<id<DVNAttributeProviderModel>> *)models {
  return [models lt_map:^id<DVNAttributeProvider>(id<DVNAttributeProviderModel> model) {
    return [model provider];
  }];
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

- (LTDynamicQuadDrawer *)drawerWithGPUStructs:(NSOrderedSet<LTGPUStruct *> *)gpuStructs {
  return [[LTDynamicQuadDrawer alloc]
          initWithVertexSource:self.renderStageConfiguration.vertexSource
          fragmentSource:self.renderStageConfiguration.fragmentSource gpuStructs:gpuStructs];
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
