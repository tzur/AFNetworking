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

__block id samplingConfiguration;
__block id geometryConfiguration;
__block id textureConfiguration;
__block id attributeConfiguration;
__block id renderConfiguration;

beforeEach(^{
  samplingConfiguration = OCMProtocolMock(@protocol(LTContinuousSamplerModel));
  geometryConfiguration = OCMProtocolMock(@protocol(DVNGeometryProviderModel));
  textureConfiguration = OCMClassMock([DVNTextureMappingStageConfiguration class]);
  attributeConfiguration = OCMClassMock([DVNAttributeStageConfiguration class]);
  renderConfiguration = OCMClassMock([DVNRenderStageConfiguration class]);
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    DVNPipelineConfiguration *configuration =
        [[DVNPipelineConfiguration alloc] initWithSamplingStageConfiguration:samplingConfiguration
                                                  geometryStageConfiguration:geometryConfiguration
                                            textureMappingStageConfiguration:textureConfiguration
                                                 attributeStageConfiguration:attributeConfiguration
                                                    renderStageConfiguration:renderConfiguration];
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

SpecEnd
