// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTInverseTransformSampler.h"

#import <numeric>

#pragma mark -
#pragma mark LTInverseTransformSampler
#pragma mark -

@interface LTInverseTransformSampler () {
  Floats _cdf;
  Floats _pdf;
}

/// Mapping between internal cdf/pdf index -> internal given \c distribution index.
@property (strong, nonatomic) NSDictionary *indexMapping;

@end

@implementation LTInverseTransformSampler

- (id)initWithFrequencies:(const Floats &)frequencies {
  if (self = [super init]) {
    [self verifyFrequencies:frequencies];
    [self createProbabilityDensityFunctionFromFrequencies:frequencies];
    [self createCumulativeDistributionFunction];
    [self initializePRNG];
  }
  return self;
}

- (void)verifyFrequencies:(const Floats &)frequencies {
  LTParameterAssert(frequencies.size(), @"Given distribution must not be empty");

  auto negative = std::find_if(frequencies.begin(), frequencies.end(), [](float value) {
    return value < 0.f;
  });
  LTParameterAssert(negative == frequencies.end(), @"All given frequencies must be non-negative");

  auto positive = std::find_if(frequencies.begin(), frequencies.end(), [](float value) {
    return value > 0.f;
  });
  LTParameterAssert(positive != frequencies.end(), @"At least one frequency must be positive");
}

- (void)createProbabilityDensityFunctionFromFrequencies:(const Floats &)frequencies {
  NSMutableDictionary *indexMapping = [NSMutableDictionary dictionary];

  float sum = std::accumulate(frequencies.begin(), frequencies.end(), 0);

  for (Floats::size_type i = 0; i < frequencies.size(); ++i) {
    indexMapping[@(_pdf.size())] = @(i);

    float value = frequencies[i];
    if (value) {
      _pdf.push_back(value / sum);
    }
  };

  self.indexMapping = [indexMapping copy];
}

- (void)createCumulativeDistributionFunction {
  _cdf.resize(_pdf.size());
  std::partial_sum(_pdf.begin(), _pdf.end(), _cdf.begin());
}

- (void)initializePRNG {
  srand48(time(0));
}

- (NSArray *)sample:(NSUInteger)times {
  NSMutableArray *samples = [NSMutableArray array];

  for (NSUInteger i = 0; i < times; ++i) {
    float random = drand48();

    // Get index and map between internal -> external.
    Floats::difference_type index =
        std::lower_bound(_cdf.cbegin(), _cdf.cend(), random) - _cdf.begin();
    NSNumber *externalIndex = self.indexMapping[@(index)];
    [samples addObject:externalIndex];
  }

  return [samples copy];
}

@end

#pragma mark -
#pragma mark LTInverseTransformSamplerFactory
#pragma mark -

@implementation LTInverseTransformSamplerFactory

- (id<LTDistributionSampler>)samplerWithFrequencies:(const Floats &)frequencies {
  return [[LTInverseTransformSampler alloc] initWithFrequencies:frequencies];
}

@end
