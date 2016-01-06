// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSampler.h"

#import "LTFloatSet.h"
#import "LTParameterizedObject.h"

NS_ASSUME_NONNULL_BEGIN

/// Object wrapping the output of the \c LTSampler object.
@interface LTSamplerOutput : NSObject <LTSamplerOutput> {
  /// Parametric values at which the parameterized object has been sampled.
  CGFloats _sampledParametricValues;
}

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c sampledParametricValues, \c mapping and the given
/// \c samplingScheme. The given \c sampledParametricValues are the parametric values at which the
/// parameterized object has been sampled. The given \c mapping constitutes the mapping from keys of
/// the sampled parameterized object to sampled values. Should be \c nil if no values were sampled.
/// The given \c samplingScheme describes the desired continuation of future sampling.
- (instancetype)initWithSampledParametricValues:(const CGFloats &)sampledParametricValues
                                        mapping:(nullable LTParameterizationKeyToValues *)mapping
    NS_DESIGNATED_INITIALIZER;

/// Mapping from keys of the sampled parameterized object to sampled values. \c nil if no values
/// were sampled.
@property (strong, nonatomic, nullable) LTParameterizationKeyToValues *mappingOfSampledValues;

@end

@implementation LTSamplerOutput

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithSampledParametricValues:(const CGFloats &)sampledParametricValues
                                        mapping:(nullable LTParameterizationKeyToValues *)mapping {
  if (self = [super init]) {
    _sampledParametricValues = sampledParametricValues;
    _mappingOfSampledValues = mapping;
  }
  return self;
}

#pragma mark -
#pragma mark LTSamplerOutput
#pragma mark -

- (CGFloats)sampledParametricValues {
  return _sampledParametricValues;
}

@end

@implementation LTSampler

#pragma mark -
#pragma mark Public interface
#pragma mark -

- (id<LTSamplerOutput>)samplesFromParameterizedObject:(id<LTParameterizedObject>)parameterizedObject
                                     usingDiscreteSet:(id<LTFloatSet>)discreteSet
                                             interval:(const lt::Interval<CGFloat> &)interval {
  CGFloats parametricValues = [discreteSet discreteValuesInInterval:interval];

  if (!parametricValues.size()) {
    return [[LTSamplerOutput alloc] initWithSampledParametricValues:{} mapping:nil];
  }

  LTParameterizationKeyToValues *mapping =
      [parameterizedObject mappingForParametricValues:parametricValues];
  return [[LTSamplerOutput alloc] initWithSampledParametricValues:parametricValues mapping:mapping];
}

@end

NS_ASSUME_NONNULL_END
