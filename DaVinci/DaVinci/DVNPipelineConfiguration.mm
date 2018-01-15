// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNPipelineConfiguration.h"

#import <LTEngine/LTContinuousSampler.h>

#import "DVNAttributeStageConfiguration.h"
#import "DVNGeometryProvider.h"
#import "DVNRenderStageConfiguration.h"
#import "DVNTextureMappingStageConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNPipelineConfiguration

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)
    initWithSamplingStageConfiguration:(id<LTContinuousSamplerModel>)samplingConfiguration
    geometryStageConfiguration:(id<DVNGeometryProviderModel>)geometryConfiguration
    textureMappingStageConfiguration:(DVNTextureMappingStageConfiguration *)textureConfiguration
    attributeStageConfiguration:(DVNAttributeStageConfiguration *)attributeConfiguration
    renderStageConfiguration:(DVNRenderStageConfiguration *)renderConfiguration {
  LTParameterAssert(samplingConfiguration);
  LTParameterAssert(geometryConfiguration);
  LTParameterAssert(textureConfiguration);
  LTParameterAssert(attributeConfiguration);
  LTParameterAssert(renderConfiguration);

  if (self = [super init]) {
    _samplingStageConfiguration = samplingConfiguration;
    _geometryStageConfiguration = geometryConfiguration;
    _textureStageConfiguration = textureConfiguration;
    _attributeStageConfiguration = attributeConfiguration;
    _renderStageConfiguration = renderConfiguration;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNPipelineConfiguration *)configuration {
  if (self == configuration) {
    return YES;
  }

  if (![configuration isKindOfClass:[DVNPipelineConfiguration class]]) {
    return NO;
  }

  return [self.samplingStageConfiguration isEqual:configuration.samplingStageConfiguration] &&
      [self.geometryStageConfiguration isEqual:configuration.geometryStageConfiguration] &&
      [self.textureStageConfiguration isEqual:configuration.textureStageConfiguration] &&
      [self.attributeStageConfiguration isEqual:configuration.attributeStageConfiguration] &&
      [self.renderStageConfiguration isEqual:configuration.renderStageConfiguration];
}

- (NSUInteger)hash {
  return self.samplingStageConfiguration.hash ^ self.geometryStageConfiguration.hash ^
      self.textureStageConfiguration.hash ^ self.attributeStageConfiguration.hash ^
      self.renderStageConfiguration.hash;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (instancetype)
    shallowCopyWithRenderStageConfiguration:(DVNRenderStageConfiguration *)configuration {
  return [[[self class] alloc] initWithSamplingStageConfiguration:self.samplingStageConfiguration
                                       geometryStageConfiguration:self.geometryStageConfiguration
                                 textureMappingStageConfiguration:self.textureStageConfiguration
                                      attributeStageConfiguration:self.attributeStageConfiguration
                                         renderStageConfiguration:configuration];
}

@end

NS_ASSUME_NONNULL_END
