// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSampleValues.h"

#import "LTParameterizationKeyToValues.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTSampleValues

@synthesize sampledParametricValues = _sampledParametricValues;
@synthesize mappingOfSampledValues = _mappingOfSampledValues;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithSampledParametricValues:(const CGFloats &)sampledParametricValues
                                        mapping:(nullable LTParameterizationKeyToValues *)mapping {
  LTParameterAssert(sampledParametricValues.size() <= INT_MAX);
  LTParameterAssert((int)sampledParametricValues.size() == mapping.numberOfValuesPerKey);

  if (self = [super init]) {
    _sampledParametricValues = sampledParametricValues;
    _mappingOfSampledValues = mapping;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
