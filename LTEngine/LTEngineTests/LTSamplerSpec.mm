// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSampler.h"

#import "LTFloatSet.h"
#import "LTParameterizationKeyToValues.h"
#import "LTParameterizedObject.h"
#import "LTSampleValues.h"
#import "LTSamplerTestUtils.h"

@interface LTTestFloatSet : NSObject <LTFloatSet>
@property (nonatomic) lt::Interval<CGFloat> receivedInterval;
@end

@implementation LTTestFloatSet

- (CGFloats)discreteValuesInInterval:(const lt::Interval<CGFloat> &)interval {
  self.receivedInterval = interval;
  return {1, 2, 3};
}

@end

SpecBegin(LTSampler)

__block LTSampler *sampler;
__block LTSamplerTestParameterizedObject *parameterizedObject;

beforeEach(^{
  sampler = [[LTSampler alloc] init];
  parameterizedObject = [[LTSamplerTestParameterizedObject alloc] init];
  parameterizedObject.minParametricValue = 0;
  parameterizedObject.maxParametricValue = 10;
  NSOrderedSet<NSString *> *keys = [NSOrderedSet orderedSetWithArray:@[@"a"]];
  cv::Mat1g values = (cv::Mat1g(1, 3) << 7, 8, 9);
  parameterizedObject.returnedMapping = [[LTParameterizationKeyToValues alloc] initWithKeys:keys
                                                                               valuesPerKey:values];
});

it(@"should correcly sample parameterized object using discrete CGFloat set, in given interval", ^{
  lt::Interval<CGFloat> interval({1, 3}, lt::Interval<CGFloat>::Closed);
  LTTestFloatSet *set = [[LTTestFloatSet alloc] init];

  parameterizedObject.expectedParametricValues = {1, 2, 3};

  id<LTSampleValues> values = [sampler samplesFromParameterizedObject:parameterizedObject
                                                     usingDiscreteSet:set interval:interval];

  expect(set.receivedInterval.min()).to.equal(interval.min());
  expect(set.receivedInterval.max()).to.equal(interval.max());
  expect(set.receivedInterval.minEndpointIncluded()).to.equal(interval.minEndpointIncluded());
  expect(set.receivedInterval.maxEndpointIncluded()).to.equal(interval.maxEndpointIncluded());
  expect(values.sampledParametricValues.size()).to.equal(3);
  expect(values.mappingOfSampledValues).toNot.beNil();
  expect(values.mappingOfSampledValues).to.equal(parameterizedObject.returnedMapping);
});

SpecEnd
