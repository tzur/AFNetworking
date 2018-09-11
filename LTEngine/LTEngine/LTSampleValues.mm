// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSampleValues.h"

#import <LTKit/LTHashExtensions.h>

#import "LTParameterizationKeyToValues.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTSampleValues

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

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTSampleValues *)sampleValues {
  if (self == sampleValues) {
    return YES;
  }

  if (![sampleValues isKindOfClass:[self class]]) {
    return NO;
  }

  return _sampledParametricValues == sampleValues.sampledParametricValues &&
      (self.mappingOfSampledValues == sampleValues.mappingOfSampledValues ||
       [self.mappingOfSampledValues isEqual:sampleValues.mappingOfSampledValues]);
}

- (NSUInteger)hash {
  size_t seed = 0;
  lt::hash_combine(seed, std::hash<CGFloats>()(_sampledParametricValues));
  lt::hash_combine(seed, self.mappingOfSampledValues.hash);
  return seed;
}

#pragma mark -
#pragma mark LTSampleValues protocol
#pragma mark -

- (instancetype)concatenatedWithSampleValues:(id<LTSampleValues>)sampleValues {
  if (!_mappingOfSampledValues && !sampleValues.mappingOfSampledValues) {
    return [[[self class] alloc] initWithSampledParametricValues:{} mapping:nil];
  }

  LTParameterAssert(!self.mappingOfSampledValues || !sampleValues.mappingOfSampledValues ||
                    [self.mappingOfSampledValues.keys
                     isEqual:sampleValues.mappingOfSampledValues.keys],
                    @"Given keys (%@) must equal keys (%@) of this instance",
                    sampleValues.mappingOfSampledValues.keys, self.mappingOfSampledValues.keys);

  CGFloats sampledParametricValues = _sampledParametricValues;
  CGFloats otherSampledParametricValues = sampleValues.sampledParametricValues;
  sampledParametricValues.insert(sampledParametricValues.end(),
                                 otherSampledParametricValues.cbegin(),
                                 otherSampledParametricValues.cend());
  cv::Mat1g concatenatedMapping;
  if (_mappingOfSampledValues && sampleValues.mappingOfSampledValues) {
    cv::hconcat(_mappingOfSampledValues.valuesPerKey,
                sampleValues.mappingOfSampledValues.valuesPerKey, concatenatedMapping);
  } else {
    concatenatedMapping = _mappingOfSampledValues ? _mappingOfSampledValues.valuesPerKey :
        sampleValues.mappingOfSampledValues.valuesPerKey;
  }
  NSOrderedSet<NSString *> *keys =
      _mappingOfSampledValues.keys ?: sampleValues.mappingOfSampledValues.keys;
  LTParameterizationKeyToValues *mapping =
      [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:concatenatedMapping];
  return [[[self class] alloc] initWithSampledParametricValues:sampledParametricValues
                                                       mapping:mapping];
}

@synthesize sampledParametricValues = _sampledParametricValues;
@synthesize mappingOfSampledValues = _mappingOfSampledValues;

@end

NS_ASSUME_NONNULL_END
