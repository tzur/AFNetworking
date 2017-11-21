// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNTextureMappingStageConfiguration.h"

#import <LTEngine/LTTexture+Factory.h>
#import <LTKitTestUtils/LTEqualityExamples.h>

#import "DVNTexCoordProvider.h"

SpecBegin(DVNTextureMappingStageConfiguration)

static id<DVNTexCoordProviderModel> const kModel =
    OCMProtocolMock(@protocol(DVNTexCoordProviderModel));

__block id textureMock;

beforeEach(^{
  textureMock = OCMClassMock([LTTexture class]);
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    DVNTextureMappingStageConfiguration *configuration =
        [[DVNTextureMappingStageConfiguration alloc] initWithTexCoordProviderModel:kModel
                                                                           texture:textureMock];
    expect(configuration.model).to.equal(kModel);
    expect(configuration.texture).to.equal(textureMock);
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNTextureMappingStageConfiguration *configuration =
      [[DVNTextureMappingStageConfiguration alloc] initWithTexCoordProviderModel:kModel
                                                                         texture:textureMock];
  DVNTextureMappingStageConfiguration *equalConfiguration =
      [[DVNTextureMappingStageConfiguration alloc] initWithTexCoordProviderModel:kModel
                                                                         texture:textureMock];
  DVNTextureMappingStageConfiguration *differentConfiguration =
      [[DVNTextureMappingStageConfiguration alloc]
       initWithTexCoordProviderModel:OCMProtocolMock(@protocol(DVNTexCoordProviderModel))
       texture:textureMock];
  DVNTextureMappingStageConfiguration *anotherDifferentConfiguration =
      [[DVNTextureMappingStageConfiguration alloc]
       initWithTexCoordProviderModel:kModel texture:OCMClassMock([LTTexture class])];
  return @{
    kLTEqualityExamplesObject: configuration,
    kLTEqualityExamplesEqualObject: equalConfiguration,
    kLTEqualityExamplesDifferentObjects: @[differentConfiguration, anotherDifferentConfiguration]
  };
});

SpecEnd
