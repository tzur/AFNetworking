// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSampler.h"

#import "LTFloatSet.h"
#import "LTParameterizedObject.h"

@interface LTTestParameterizedObject : NSObject <LTParameterizedObject>
@property (nonatomic) CGFloat minParametricValue;
@property (nonatomic) CGFloat maxParametricValue;
@property (nonatomic) CGFloats expectedParametricValues;
@property (nonatomic) LTParameterizationKeyToValues *returnedMapping;
@end

@implementation LTTestParameterizedObject

@synthesize parameterizationKeys = _parameterizationKeys;

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

- (LTParameterizationKeyToValue *)mappingForParametricValue:(__unused CGFloat)value {
  return nil;
}

- (LTParameterizationKeyToValues *)mappingForParametricValues:(const CGFloats &)values {
  if (values.size() != self.expectedParametricValues.size()) {
    return nil;
  }

  for (NSUInteger i = 0; i < values.size(); ++i) {
    if (values[i] != self.expectedParametricValues[i]) {
      return nil;
    }
  }
  return self.returnedMapping;
}

- (CGFloat)floatForParametricValue:(__unused CGFloat)value key:(NSString __unused *)key {
  return 0;
}

- (CGFloats)floatsForParametricValues:(const CGFloats __unused &)values
                                  key:(NSString __unused *)key {
  return {};
}

@end

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
__block LTTestParameterizedObject *parameterizedObject;

beforeEach(^{
  parameterizedObject = [[LTTestParameterizedObject alloc] init];
  parameterizedObject.minParametricValue = 0;
  parameterizedObject.maxParametricValue = 10;
  parameterizedObject.returnedMapping = [[LTParameterizationKeyToValues alloc] init];

  sampler = [[LTSampler alloc] initWithParameterizedObject:parameterizedObject];
});

it(@"should correcly sample parameterized object using discrete CGFloat set, in given interval", ^{
  lt::Interval<CGFloat> interval({1, 3}, lt::Interval<CGFloat>::Closed);
  LTTestFloatSet *set = [[LTTestFloatSet alloc] init];

  parameterizedObject.expectedParametricValues = {1, 2, 3};

  id<LTSamplerOutput> output = [sampler samplesUsingDiscreteSet:set interval:interval];

  expect(set.receivedInterval.min()).to.equal(interval.min());
  expect(set.receivedInterval.max()).to.equal(interval.max());
  expect(set.receivedInterval.minEndpointIncluded()).to.equal(interval.minEndpointIncluded());
  expect(set.receivedInterval.maxEndpointIncluded()).to.equal(interval.maxEndpointIncluded());
  expect(output.sampledParametricValues.size()).to.equal(3);
  expect(output.mappingOfSampledValues).toNot.beNil();
  expect(output.mappingOfSampledValues).to.equal(parameterizedObject.returnedMapping);
});

SpecEnd
