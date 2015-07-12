// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTInverseTransformSampler.h"

#import "LTRandom.h"

#import <numeric>

#pragma mark -
#pragma mark LTInverseTransformSampler
#pragma mark -

@interface LTInverseTransformSampler () {
  Floats _cdf;
  Floats _pdf;

  /// Mapping between internal cdf/pdf index -> internal given \c frequencies index.
  Floats _indexMapping;
}

/// The random generator used by the sampler.
@property (strong, nonatomic) LTRandom *random;

@end

@implementation LTInverseTransformSampler

- (instancetype)initWithFrequencies:(const Floats &)frequencies random:(LTRandom *)random {
  if (self = [super init]) {
    [self verifyFrequencies:frequencies];
    [self createProbabilityDensityFunctionFromFrequencies:frequencies];
    [self createCumulativeDistributionFunction];
    self.random = random;
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
  float sum = std::accumulate(frequencies.begin(), frequencies.end(), 0);

  _indexMapping.clear();
  for (Floats::size_type i = 0; i < frequencies.size(); ++i) {
    if (_indexMapping.size() > _pdf.size()) {
      _indexMapping.back() = i;
    } else {
      _indexMapping.push_back(i);
    }

    float value = frequencies[i];
    if (value) {
      _pdf.push_back(value / sum);
    }
  };
}

- (void)createCumulativeDistributionFunction {
  _cdf.resize(_pdf.size());
  std::partial_sum(_pdf.begin(), _pdf.end(), _cdf.begin());
  // Because of numerical errors, sum will usually be a bit smaller than 1. Therefore, Make sure the
  // last CDF element is indeed 1 to avoid indexing issues while sampling.
  _cdf.back() = 1.f;
}

- (Floats)sample:(NSUInteger)times {
  Floats samples;
  for (NSUInteger i = 0; i < times; ++i) {
    float random = [self.random randomDouble];

    // Get index and map between internal -> external.
    Floats::difference_type index =
        std::lower_bound(_cdf.cbegin(), _cdf.cend(), random) - _cdf.cbegin();
    samples.push_back(_indexMapping[index]);
  }
  return samples;
}

@end

#pragma mark -
#pragma mark LTInverseTransformSamplerFactory
#pragma mark -

@implementation LTInverseTransformSamplerFactory

- (id<LTDistributionSampler>)samplerWithFrequencies:(const Floats &)frequencies
                                             random:(LTRandom *)random {
  return [[LTInverseTransformSampler alloc] initWithFrequencies:frequencies random:random];
}

@end
