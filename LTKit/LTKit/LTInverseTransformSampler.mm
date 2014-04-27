// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTInverseTransformSampler.h"

#import <numeric>

#pragma mark -
#pragma mark LTInverseTransformSampler
#pragma mark -

typedef std::vector<float> Floats;

@interface LTInverseTransformSampler () {
  Floats _cdf;
  Floats _pdf;
}

/// Mapping between internal cdf/pdf index -> internal given \c distribution index.
@property (strong, nonatomic) NSDictionary *indexMapping;

@end

@implementation LTInverseTransformSampler

- (id)initWithFrequencies:(NSArray *)frequencies {
  if (self = [super init]) {
    [self verifyFrequencies:frequencies];
    [self createProbabilityDensityFunctionFromFrequencies:frequencies];
    [self createCumulativeDistributionFunction];
    [self initializePRNG];
  }
  return self;
}

- (void)verifyFrequencies:(NSArray *)frequencies {
  LTParameterAssert(frequencies.count, @"Given distribution must not be empty");

  LTParameterAssert([[frequencies valueForKeyPath:@"@sum.self"] floatValue] > 0.f,
                    @"Frequencies sum must be positive");

  NSPredicate *aboveZeroPredicate = [NSPredicate predicateWithFormat:@"floatValue > 0"];
  LTParameterAssert([frequencies filteredArrayUsingPredicate:aboveZeroPredicate].count,
                    @"At least one frequency must be positive");
}

- (void)createProbabilityDensityFunctionFromFrequencies:(NSArray *)frequencies {
  NSMutableDictionary *indexMapping = [NSMutableDictionary dictionary];

  float sum = [[frequencies valueForKeyPath:@"@sum.self"] floatValue];

  [frequencies enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *) {
    float value = [obj floatValue];

    indexMapping[@(_pdf.size())] = @(idx);

    if (value) {
      _pdf.push_back(value / sum);
    }
  }];

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

- (id<LTDistributionSampler>)samplerWithFrequencies:(NSArray *)frequencies {
  return [[LTInverseTransformSampler alloc] initWithFrequencies:frequencies];
}

@end
