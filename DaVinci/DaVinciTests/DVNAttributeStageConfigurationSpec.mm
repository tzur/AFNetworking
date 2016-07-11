// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNAttributeStageConfiguration.h"

SpecBegin(DVNAttributeStageConfiguration)

context(@"initialization", ^{
  it(@"should initialize correctly without parameters", ^{
    DVNAttributeStageConfiguration *configuration = [[DVNAttributeStageConfiguration alloc] init];
    expect(configuration.attributeProviderModels).to.beEmpty();
  });

  it(@"should initialize correctly", ^{
    NSArray<id<DVNAttributeProviderModel>> *models =
        @[OCMProtocolMock(@protocol(DVNAttributeProviderModel))];
    DVNAttributeStageConfiguration *configuration =
        [[DVNAttributeStageConfiguration alloc] initWithAttributeProviderModels:models];
    expect(configuration.attributeProviderModels).to.equal(models);
  });
});

SpecEnd
