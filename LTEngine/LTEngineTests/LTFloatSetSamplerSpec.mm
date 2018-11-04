// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTFloatSetSampler.h"

#import "LTEasyVectorBoxing.h"
#import "LTFloatSet.h"
#import "LTOpenCVExtensions.h"
#import "LTParameterizationKeyToValues.h"
#import "LTSampleValues.h"
#import "LTSamplerTestUtils.h"

@interface LTFloatSetSamplerTestSet : NSObject <LTFloatSet>
@property (nonatomic) CGFloats values;
@end

@implementation LTFloatSetSamplerTestSet

- (CGFloats)discreteValuesInInterval:(__unused const lt::Interval<CGFloat> &)interval {
  return self.values;
}

@end

SpecBegin(LTFloatSetSamplerModel)

__block LTFloatSetSamplerTestSet *floatSet;
__block lt::Interval<CGFloat> interval;

beforeEach(^{
  floatSet = [[LTFloatSetSamplerTestSet alloc] init];
  interval = lt::Interval<CGFloat>({0, 1}, lt::Interval<CGFloat>::EndpointInclusion::Closed,
                                   lt::Interval<CGFloat>::EndpointInclusion::Closed);
});

it(@"should initialize correcty", ^{
  LTFloatSetSamplerModel *model = [[LTFloatSetSamplerModel alloc] initWithFloatSet:floatSet
                                                                          interval:interval];
  expect(model.floatSet).to.equal(floatSet);
  expect(model.interval == interval).to.beTruthy();
});

it(@"should return a sampler", ^{
  LTFloatSetSamplerModel *model = [[LTFloatSetSamplerModel alloc] initWithFloatSet:floatSet
                                                                          interval:interval];
  expect([model sampler]).toNot.beNil();
  expect([model sampler]).to.beKindOf([LTFloatSetSampler class]);
});

it(@"should return a sampler with the same model", ^{
  LTFloatSetSamplerModel *model = [[LTFloatSetSamplerModel alloc] initWithFloatSet:floatSet
                                                                          interval:interval];
  LTFloatSetSampler *sampler = [model sampler];
  expect([sampler currentModel]).to.equal(model);
});

SpecEnd

SpecBegin(LTFloatSetSampler)

__block LTFloatSetSamplerTestSet *floatSet;
__block lt::Interval<CGFloat> interval;
__block LTFloatSetSampler *sampler;
__block LTSamplerTestParameterizedObject *parameterizedObject;
__block NSOrderedSet<NSString *> *keys;

beforeEach(^{
  floatSet = [[LTFloatSetSamplerTestSet alloc] init];
  interval = lt::Interval<CGFloat>({0, 2.5}, lt::Interval<CGFloat>::EndpointInclusion::Closed,
                                   lt::Interval<CGFloat>::EndpointInclusion::Closed);
  LTFloatSetSamplerModel *model = [[LTFloatSetSamplerModel alloc] initWithFloatSet:floatSet
                                                                          interval:interval];
  sampler = [model sampler];
  parameterizedObject = [[LTSamplerTestParameterizedObject alloc] init];
  parameterizedObject.minParametricValue = 0;
  parameterizedObject.maxParametricValue = 10;
  keys = [NSOrderedSet orderedSetWithArray:@[@"a"]];
});

context(@"sampling", ^{
  it(@"should sample a given parameterized object", ^{
    CGFloats values = {1, 2, 3};
    floatSet.values = values;

    parameterizedObject.expectedParametricValues = values;
    cv::Mat1g matrix = (cv::Mat1g(1, 3) << 7, 8, 9);
    LTParameterizationKeyToValues *mapping =
        [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:matrix];
    parameterizedObject.returnedMapping = mapping;

    id<LTSampleValues> sampleValues =
        [sampler nextSamplesFromParameterizedObject:parameterizedObject
                              constrainedToInterval:interval];
    expect($(sampleValues.sampledParametricValues)).to.equal($(values));
    expect(sampleValues.mappingOfSampledValues).to.equal(mapping);
  });

  it(@"should provide valid sample values when object is sampled outside parametric range", ^{
    CGFloats values = {};
    floatSet.values = values;

    cv::Mat1g matrix(1, 0);
    LTParameterizationKeyToValues *mapping =
        [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:matrix];
    parameterizedObject.returnedMapping = mapping;

    id<LTSampleValues> sampleValues =
        [sampler nextSamplesFromParameterizedObject:parameterizedObject
                              constrainedToInterval:interval];

    expect($(sampleValues.sampledParametricValues)).to.equal($(values));
    expect(sampleValues.mappingOfSampledValues).to.beNil();
  });

  it(@"should consecutively sample a given parameterized object, using closed interval", ^{
    floatSet.values = {1};
    parameterizedObject.expectedParametricValues = floatSet.values;

    cv::Mat1g matrix(1, 1, 7);
    LTParameterizationKeyToValues *mapping =
        [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:matrix];
    parameterizedObject.returnedMapping = mapping;

    lt::Interval<CGFloat> firstInterval({0, 1}, lt::Interval<CGFloat>::EndpointInclusion::Closed,
                                        lt::Interval<CGFloat>::EndpointInclusion::Closed);

    id<LTSampleValues> sampleValues =
        [sampler nextSamplesFromParameterizedObject:parameterizedObject
                              constrainedToInterval:firstInterval];
    expect($(sampleValues.sampledParametricValues)).to.equal($(floatSet.values));
    expect(sampleValues.mappingOfSampledValues).to.equal(mapping);

    floatSet.values = {0};
    parameterizedObject.expectedParametricValues = floatSet.values;

    lt::Interval<CGFloat> secondInterval({1, 2}, lt::Interval<CGFloat>::EndpointInclusion::Open,
                                         lt::Interval<CGFloat>::EndpointInclusion::Open);

    sampleValues = [sampler nextSamplesFromParameterizedObject:parameterizedObject
                                         constrainedToInterval:secondInterval];
    expect($(sampleValues.sampledParametricValues)).to.equal($(floatSet.values));
    expect(sampleValues.mappingOfSampledValues).to.equal(mapping);
  });

  it(@"should consecutively sample a given parameterized object, using open interval", ^{
    floatSet.values = {0};
    parameterizedObject.expectedParametricValues = floatSet.values;

    cv::Mat1g matrix(1, 1, 1);
    LTParameterizationKeyToValues *mapping =
        [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:matrix];
    parameterizedObject.returnedMapping = mapping;

    lt::Interval<CGFloat> firstInterval({0, 1}, lt::Interval<CGFloat>::EndpointInclusion::Closed,
                                        lt::Interval<CGFloat>::EndpointInclusion::Open);

    id<LTSampleValues> sampleValues =
        [sampler nextSamplesFromParameterizedObject:parameterizedObject
                              constrainedToInterval:firstInterval];
    expect($(sampleValues.sampledParametricValues)).to.equal($(floatSet.values));
    expect(sampleValues.mappingOfSampledValues).to.equal(mapping);

    floatSet.values = {1};
    parameterizedObject.expectedParametricValues = floatSet.values;

    lt::Interval<CGFloat> secondInterval({1, 2}, lt::Interval<CGFloat>::EndpointInclusion::Closed,
                                         lt::Interval<CGFloat>::EndpointInclusion::Open);

    sampleValues = [sampler nextSamplesFromParameterizedObject:parameterizedObject
                                         constrainedToInterval:secondInterval];
    expect($(sampleValues.sampledParametricValues)).to.equal($(floatSet.values));
    expect(sampleValues.mappingOfSampledValues).to.equal(mapping);
  });
});

context(@"model", ^{
  beforeEach(^{
    floatSet.values = {0};
    parameterizedObject.expectedParametricValues = floatSet.values;

    cv::Mat1g matrix(1, 1, 1);
    LTParameterizationKeyToValues *mapping =
        [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:matrix];
    parameterizedObject.returnedMapping = mapping;
  });

  it(@"should provide a correct model after a single sample of a given parameterized object", ^{
    lt::Interval<CGFloat> sampleInterval({0, 1}, lt::Interval<CGFloat>::EndpointInclusion::Closed,
                                         lt::Interval<CGFloat>::EndpointInclusion::Open);

    [sampler nextSamplesFromParameterizedObject:parameterizedObject
                          constrainedToInterval:sampleInterval];

    LTFloatSetSamplerModel *model = [sampler currentModel];
    expect(model.floatSet).to.equal(floatSet);
    expect(model.interval.inf()).to.equal(1);
    expect(model.interval.sup()).to.equal(2.5);
    expect(model.interval.infIncluded()).to.beTruthy();
    expect(model.interval.supIncluded()).to.beTruthy();
  });

  it(@"should provide correct model after consecutive samples of a given parameterized object", ^{
    lt::Interval<CGFloat> firstInterval({0, 1}, lt::Interval<CGFloat>::EndpointInclusion::Closed,
                                        lt::Interval<CGFloat>::EndpointInclusion::Open);
    lt::Interval<CGFloat> secondInterval({1, 2}, lt::Interval<CGFloat>::EndpointInclusion::Closed,
                                         lt::Interval<CGFloat>::EndpointInclusion::Closed);

    [sampler nextSamplesFromParameterizedObject:parameterizedObject
                          constrainedToInterval:firstInterval];
    [sampler nextSamplesFromParameterizedObject:parameterizedObject
                          constrainedToInterval:secondInterval];

    LTFloatSetSamplerModel *model = [sampler currentModel];
    expect(model.floatSet).to.equal(floatSet);
    expect(model.interval.inf()).to.equal(2);
    expect(model.interval.sup()).to.equal(2.5);
    expect(model.interval.infIncluded()).to.beFalsy();
    expect(model.interval.supIncluded()).to.beTruthy();
  });
});

SharedExamplesEnd
