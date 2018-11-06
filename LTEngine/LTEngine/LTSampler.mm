// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSampler.h"

#import "LTFloatSet.h"
#import "LTParameterizedObject.h"
#import "LTSampleValues.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTSampler

#pragma mark -
#pragma mark Public interface
#pragma mark -

- (id<LTSampleValues>)samplesFromParameterizedObject:(id<LTParameterizedObject>)parameterizedObject
                                     usingDiscreteSet:(id<LTFloatSet>)discreteSet
                                             interval:(const lt::Interval<CGFloat> &)interval {
  std::vector<CGFloat> parametricValues = [discreteSet discreteValuesInInterval:interval];

  if (!parametricValues.size()) {
    return [[LTSampleValues alloc] initWithSampledParametricValues:{} mapping:nil];
  }

  LTParameterizationKeyToValues *mapping =
      [parameterizedObject mappingForParametricValues:parametricValues];
  return [[LTSampleValues alloc] initWithSampledParametricValues:parametricValues mapping:mapping];
}

@end

NS_ASSUME_NONNULL_END
