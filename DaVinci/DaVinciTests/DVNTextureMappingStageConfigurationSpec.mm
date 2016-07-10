// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNTextureMappingStageConfiguration.h"

#import <LTEngine/LTTexture.h>

#import "DVNTexCoordProvider.h"

SpecBegin(DVNTextureMappingStageConfiguration)

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    id<DVNTexCoordProviderModel> modelMock = OCMProtocolMock(@protocol(DVNTexCoordProviderModel));
    LTTexture *textureMock = OCMClassMock([LTTexture class]);
    DVNTextureMappingStageConfiguration *configuration =
        [[DVNTextureMappingStageConfiguration alloc] initWithTexCoordProviderModel:modelMock
                                                                           texture:textureMock];
    expect(configuration.texCoordProviderModel).to.equal(modelMock);
    expect(configuration.texture).to.equal(textureMock);
  });
});

SpecEnd
