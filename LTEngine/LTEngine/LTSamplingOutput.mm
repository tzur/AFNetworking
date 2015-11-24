// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSamplingOutput.h"

#import "LTSamplingScheme.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTSamplingOutput () {
  /// Parametric values at which the parameterized object has been sampled.
  CGFloats _sampledParametricValues;
}

/// Mapping from keys of the sampled parameterized object to sampled values. \c nil if no values
/// were sampled.
@property (strong, readwrite, nonatomic, nullable)
    LTParameterizationKeyToValues *mappingOfSampledValues;

/// Sampling scheme describing the desired continuation of the sampling applied to create this
/// output.
@property (readwrite, nonatomic) id<LTSamplingScheme> samplingScheme;

@end

@implementation LTSamplingOutput

- (instancetype)initWithSampledParametricValues:(const CGFloats &)sampledParametricValues
                                        mapping:(nullable LTParameterizationKeyToValues *)mapping
                                 samplingScheme:(id<LTSamplingScheme>)samplingScheme {
  if (self = [super init]) {
    _sampledParametricValues = sampledParametricValues;
    self.mappingOfSampledValues = mapping;
    self.samplingScheme = samplingScheme;
  }
  return self;
}

- (CGFloats)sampledParametricValues {
  return _sampledParametricValues;
}

@end

NS_ASSUME_NONNULL_END
