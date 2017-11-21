// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNAttributeStageConfiguration.h"

#import <LTKitTestUtils/LTEqualityExamples.h>

SpecBegin(DVNAttributeStageConfiguration)

context(@"initialization", ^{
  it(@"should initialize correctly without parameters", ^{
    DVNAttributeStageConfiguration *configuration = [[DVNAttributeStageConfiguration alloc] init];
    expect(configuration.models).to.beEmpty();
  });

  it(@"should initialize correctly", ^{
    NSArray<id<DVNAttributeProviderModel>> *models =
        @[OCMProtocolMock(@protocol(DVNAttributeProviderModel))];
    DVNAttributeStageConfiguration *configuration =
        [[DVNAttributeStageConfiguration alloc] initWithAttributeProviderModels:models];
    expect(configuration.models).to.equal(models);
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  NSArray<id<DVNAttributeProviderModel>> *models =
      @[OCMProtocolMock(@protocol(DVNAttributeProviderModel))];

  DVNAttributeStageConfiguration *differentConfiguration =
      [[DVNAttributeStageConfiguration alloc]
       initWithAttributeProviderModels:@[OCMProtocolMock(@protocol(DVNAttributeProviderModel))]];

  return @{
    kLTEqualityExamplesObject: [[DVNAttributeStageConfiguration alloc]
                                initWithAttributeProviderModels:models],
    kLTEqualityExamplesEqualObject: [[DVNAttributeStageConfiguration alloc]
                                     initWithAttributeProviderModels:models],
    kLTEqualityExamplesDifferentObjects: @[differentConfiguration]
  };
});

SpecEnd
