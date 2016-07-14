// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNSplineRenderModel.h"

#import <LTEngine/LTControlPointModel.h>
#import <LTKitTests/LTEqualityExamples.h>

#import "DVNPipelineConfiguration.h"

SpecBegin(DVNSplineRenderModel)
__block id controlPointModel;
__block id configuration;
__block lt::Interval<CGFloat> endInterval;

beforeEach(^{
  controlPointModel = OCMClassMock([LTControlPointModel class]);
  configuration = OCMClassMock([DVNPipelineConfiguration class]);
  endInterval = lt::Interval<CGFloat>({1, 2}, lt::Interval<CGFloat>::EndpointInclusion::Closed);
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    DVNSplineRenderModel *model =
        [[DVNSplineRenderModel alloc] initWithControlPointModel:controlPointModel
                                                  configuration:configuration
                                                    endInterval:endInterval];
    expect(model.controlPointModel).to.equal(controlPointModel);
    expect(model.configuration).to.equal(configuration);
    expect(model.endInterval == endInterval).to.beTruthy();
  });

  context(@"invalid initialization attempts", ^{
    it(@"should raise when attempting to initialize with an interval with negative min value", ^{
      lt::Interval<CGFloat> invalidInterval({-1, 2},
                                            lt::Interval<CGFloat>::EndpointInclusion::Open);
      expect(^{
        DVNSplineRenderModel __unused *model =
            [[DVNSplineRenderModel alloc] initWithControlPointModel:controlPointModel
                                                      configuration:configuration
                                                        endInterval:invalidInterval];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNSplineRenderModel *model =
      [[DVNSplineRenderModel alloc] initWithControlPointModel:controlPointModel
                                                configuration:configuration
                                                  endInterval:endInterval];
  DVNSplineRenderModel *equalModel =
      [[DVNSplineRenderModel alloc] initWithControlPointModel:controlPointModel
                                                configuration:configuration
                                                  endInterval:endInterval];
  DVNSplineRenderModel *modelWithDifferentControlPointModel =
      [[DVNSplineRenderModel alloc]
       initWithControlPointModel:OCMClassMock([LTControlPointModel class])
       configuration:configuration
       endInterval:endInterval];
  DVNSplineRenderModel *modelWithDifferentConfiguration =
      [[DVNSplineRenderModel alloc]
       initWithControlPointModel:controlPointModel
       configuration:OCMClassMock([DVNPipelineConfiguration class])
       endInterval:endInterval];
  DVNSplineRenderModel *modelWithDifferentInterval =
      [[DVNSplineRenderModel alloc]
       initWithControlPointModel:controlPointModel
       configuration:OCMClassMock([DVNPipelineConfiguration class])
       endInterval:lt::Interval<CGFloat>({0, 1},
                                         lt::Interval<CGFloat>::EndpointInclusion::Closed)];
  return @{
    kLTEqualityExamplesObject: model,
    kLTEqualityExamplesEqualObject: equalModel,
    kLTEqualityExamplesDifferentObjects: @[modelWithDifferentControlPointModel,
                                           modelWithDifferentConfiguration,
                                           modelWithDifferentInterval]
  };
});

SpecEnd
