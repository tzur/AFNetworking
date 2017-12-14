// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNPipelineConfiguration.h"

#import <LTEngine/LTContinuousSampler.h>
#import <LTKitTestUtils/LTEqualityExamples.h>

#import "DVNAttributeStageConfiguration.h"
#import "DVNGeometryProvider.h"
#import "DVNRenderStageConfiguration.h"
#import "DVNTextureMappingStageConfiguration.h"

SpecBegin(DVNPipelineConfiguration)

__block id<LTContinuousSamplerModel> samplingConfiguration;
__block id<DVNGeometryProviderModel> geometryConfiguration;
__block DVNTextureMappingStageConfiguration *textureConfiguration;
__block DVNAttributeStageConfiguration *attributeConfiguration;
__block DVNRenderStageConfiguration *renderConfiguration;
__block DVNPipelineConfiguration *configuration;

beforeEach(^{
  samplingConfiguration = OCMProtocolMock(@protocol(LTContinuousSamplerModel));
  geometryConfiguration = OCMProtocolMock(@protocol(DVNGeometryProviderModel));
  textureConfiguration = OCMClassMock([DVNTextureMappingStageConfiguration class]);
  attributeConfiguration = OCMClassMock([DVNAttributeStageConfiguration class]);
  renderConfiguration = OCMClassMock([DVNRenderStageConfiguration class]);

  configuration =
      [[DVNPipelineConfiguration alloc] initWithSamplingStageConfiguration:samplingConfiguration
                                                geometryStageConfiguration:geometryConfiguration
                                          textureMappingStageConfiguration:textureConfiguration
                                               attributeStageConfiguration:attributeConfiguration
                                                  renderStageConfiguration:renderConfiguration];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(configuration.samplingStageConfiguration).to.equal(samplingConfiguration);
    expect(configuration.geometryStageConfiguration).to.equal(geometryConfiguration);
    expect(configuration.textureStageConfiguration).to.equal(textureConfiguration);
    expect(configuration.attributeStageConfiguration).to.equal(attributeConfiguration);
    expect(configuration.renderStageConfiguration).to.equal(renderConfiguration);
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNPipelineConfiguration *configuration =
      [[DVNPipelineConfiguration alloc] initWithSamplingStageConfiguration:samplingConfiguration
                                                geometryStageConfiguration:geometryConfiguration
                                          textureMappingStageConfiguration:textureConfiguration
                                               attributeStageConfiguration:attributeConfiguration
                                                  renderStageConfiguration:renderConfiguration];
  DVNPipelineConfiguration *equalConfiguration =
      [[DVNPipelineConfiguration alloc] initWithSamplingStageConfiguration:samplingConfiguration
                                                geometryStageConfiguration:geometryConfiguration
                                          textureMappingStageConfiguration:textureConfiguration
                                               attributeStageConfiguration:attributeConfiguration
                                                  renderStageConfiguration:renderConfiguration];
  DVNPipelineConfiguration *differentConfiguration =
      [[DVNPipelineConfiguration alloc]
       initWithSamplingStageConfiguration:OCMProtocolMock(@protocol(LTContinuousSamplerModel))
       geometryStageConfiguration:geometryConfiguration
       textureMappingStageConfiguration:textureConfiguration
       attributeStageConfiguration:attributeConfiguration
       renderStageConfiguration:renderConfiguration];
  return @{
    kLTEqualityExamplesObject: configuration,
    kLTEqualityExamplesEqualObject: equalConfiguration,
    kLTEqualityExamplesDifferentObjects: @[differentConfiguration]
  };
});

context(@"instance creation with updated properties", ^{
  it(@"should create a new instance with a given render stage configuration", ^{
    DVNRenderStageConfiguration *otherRenderConfiguration =
        OCMClassMock([DVNRenderStageConfiguration class]);

    DVNPipelineConfiguration *updatedConfiguration =
        [configuration shallowCopyWithRenderStageConfiguration:otherRenderConfiguration];

    expect(updatedConfiguration.samplingStageConfiguration)
        .to.beIdenticalTo(configuration.samplingStageConfiguration);
    expect(updatedConfiguration.geometryStageConfiguration)
        .to.beIdenticalTo(configuration.geometryStageConfiguration);
    expect(updatedConfiguration.textureStageConfiguration)
        .to.beIdenticalTo(configuration.textureStageConfiguration);
    expect(updatedConfiguration.attributeStageConfiguration)
        .to.beIdenticalTo(configuration.attributeStageConfiguration);
    expect(updatedConfiguration.renderStageConfiguration)
        .toNot.equal(configuration.renderStageConfiguration);
    expect(updatedConfiguration.renderStageConfiguration)
        .to.beIdenticalTo(otherRenderConfiguration);
  });
});

SpecEnd
