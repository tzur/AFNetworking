// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTFloatSetParametricValueProvider.h"

#import "LTEasyVectorBoxing.h"
#import "LTParameterizedObject.h"
#import "LTPeriodicFloatSet.h"

SpecBegin(LTFloatSetParametricValueProvider)

__block LTPeriodicFloatSet *floatSet;
__block lt::Interval<CGFloat> interval;

beforeEach(^{
  floatSet = [[LTPeriodicFloatSet alloc] initWithPivotValue:0 numberOfValuesPerSequence:1
                                              valueDistance:1 sequenceDistance:1];
  interval = lt::Interval<CGFloat>({0, 10}, lt::Interval<CGFloat>::EndpointInclusion::Closed,
                                   lt::Interval<CGFloat>::EndpointInclusion::Closed);
});

context(@"initialization", ^{
  it(@"should initialize a model with the provided parameters", ^{
    LTFloatSetParametricValueProviderModel *model =
        [[LTFloatSetParametricValueProviderModel alloc] initWithFloatSet:floatSet
                                                                interval:interval];
    expect(model).toNot.beNil();
    expect(model.floatSet).to.equal(floatSet);
    expect(model.interval == interval).to.beTruthy();
  });
});

context(@"LTContinuousParametricValueProviderModel protocol", ^{
  it(@"should create a provider from a model", ^{
    LTFloatSetParametricValueProviderModel *model =
        [[LTFloatSetParametricValueProviderModel alloc] initWithFloatSet:floatSet
                                                                interval:interval];
    LTFloatSetParametricValueProvider *provider = [model provider];
    expect(provider).toNot.beNil();
  });
});

context(@"LTContinuousParametricValueProvider protocol", ^{
  __block LTFloatSetParametricValueProviderModel *model;
  __block LTFloatSetParametricValueProvider *provider;

  beforeEach(^{
    model = [[LTFloatSetParametricValueProviderModel alloc] initWithFloatSet:floatSet
                                                                    interval:interval];
    provider = [model provider];
  });

  context(@"providing parametric values", ^{
    it(@"should provide parametric values for a parameterized object", ^{
      id parameterizedObjectMock = OCMProtocolMock(@protocol(LTParameterizedObject));
      OCMStub([parameterizedObjectMock minParametricValue]).andReturn(0);
      OCMStub([parameterizedObjectMock maxParametricValue]).andReturn(2);

      std::vector<CGFloat> values =
          [provider nextParametricValuesForParameterizedObject:parameterizedObjectMock];

      std::vector<CGFloat> expectedValues = {0, 1, 2};
      expect($(values)).to.equal($(expectedValues));
    });

    it(@"should provide parametric values for a parameterized object with increasing range", ^{
      id parameterizedObjectMock = OCMProtocolMock(@protocol(LTParameterizedObject));
      OCMExpect([parameterizedObjectMock minParametricValue]).andReturn(0);
      OCMExpect([parameterizedObjectMock maxParametricValue]).andReturn(2);
      std::vector<CGFloat> values =
          [provider nextParametricValuesForParameterizedObject:parameterizedObjectMock];

      OCMExpect([parameterizedObjectMock minParametricValue]).andReturn(0);
      OCMExpect([parameterizedObjectMock maxParametricValue]).andReturn(7);
      values = [provider nextParametricValuesForParameterizedObject:parameterizedObjectMock];

      std::vector<CGFloat> expectedValues = {3, 4, 5, 6, 7};
      expect($(values)).to.equal($(expectedValues));
      OCMVerifyAll(parameterizedObjectMock);
    });

    it(@"should provide no parametric values for a parameterized object with no overlap", ^{
      id parameterizedObjectMock = OCMProtocolMock(@protocol(LTParameterizedObject));
      OCMStub([parameterizedObjectMock minParametricValue]).andReturn(11);
      OCMStub([parameterizedObjectMock maxParametricValue]).andReturn(20);

      std::vector<CGFloat> values =
          [provider nextParametricValuesForParameterizedObject:parameterizedObjectMock];

      expect($(values)).to.beEmpty();
    });
  });

  context(@"model extraction", ^{
    it(@"should return the initial model in initial state", ^{
      LTFloatSetParametricValueProvider *provider = [model provider];
      LTFloatSetParametricValueProviderModel *currentModel = [provider currentModel];
      expect(currentModel).to.equal(model);
    });

    it(@"should return a correct current model", ^{
      id parameterizedObjectMock = OCMProtocolMock(@protocol(LTParameterizedObject));
      OCMStub([parameterizedObjectMock minParametricValue]).andReturn(0);
      OCMStub([parameterizedObjectMock maxParametricValue]).andReturn(2);
      [provider nextParametricValuesForParameterizedObject:parameterizedObjectMock];

      LTFloatSetParametricValueProviderModel *currentModel = [provider currentModel];

      lt::Interval<CGFloat> expectedInterval({2, 10},
                                             lt::Interval<CGFloat>::EndpointInclusion::Open,
                                             lt::Interval<CGFloat>::EndpointInclusion::Closed);
      expect(currentModel.floatSet).to.equal(floatSet);
      expect(currentModel.interval == expectedInterval).to.beTruthy();
    });
  });
});

SpecEnd
