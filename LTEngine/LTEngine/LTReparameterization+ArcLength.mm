// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTReparameterization+ArcLength.h"

#import "LTParameterizedObject.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTReparameterization (ArcLength)

+ (nullable instancetype)arcLengthReparameterizationForObject:(id<LTParameterizedObject>)object
                                              numberOfSamples:(NSUInteger)numberOfSamples
                                           minParametricValue:(CGFloat)minParametricValue
                            parameterizationKeyForXCoordinate:(NSString *)xKey
                            parameterizationKeyForYCoordinate:(NSString *)yKey {
  LTParameterAssert(numberOfSamples > 1, @"The given number of samples must be greater than 1");
  LTParameterAssert([object.parameterizationKeys containsObject:xKey],
                    @"Key (%@) not contained in parameterization keys (%@)", xKey,
                    object.parameterizationKeys.description);
  LTParameterAssert([object.parameterizationKeys containsObject:yKey],
                    @"Key (%@) not contained in parameterization keys (%@)", yKey,
                    object.parameterizationKeys.description);

  std::vector<CGFloat> parametricValues = [self parametricValuesForObject:object
                                                          numberOfSamples:numberOfSamples];

  std::vector<CGFloat> xCoordinates = [object floatsForParametricValues:parametricValues key:xKey];
  std::vector<CGFloat> yCoordinates = [object floatsForParametricValues:parametricValues key:yKey];
  LTParameterAssert(xCoordinates.size() == yCoordinates.size(),
                    @"Size (%lu) of x-coordinates doesn't equal size (%lu) of y-coordinates",
                    (unsigned long)xCoordinates.size(), (unsigned long)yCoordinates.size());

  std::vector<CGFloat> distances = [self distancesForXCoordinates:xCoordinates
                                                     yCoordinates:yCoordinates
                                               minParametricValue:minParametricValue];
  if (distances.front() == distances.back()) {
    // Object cannot be reparameterized.
    return nil;
  }
  return [[LTReparameterization alloc] initWithMapping:distances];
}

+ (std::vector<CGFloat>)parametricValuesForObject:(id<LTParameterizedObject>)object
                                  numberOfSamples:(NSUInteger)numberOfSamples {
  std::vector<CGFloat> values(numberOfSamples);
  CGFloat min = object.minParametricValue;
  CGFloat max = object.maxParametricValue;
  CGFloat step = 1.0 / (numberOfSamples - 1);
  for (NSUInteger i = 0; i < numberOfSamples; ++i) {
    CGFloat canonicParametricValue = i * step;
    CGFloat parametricValue = min * (1 - canonicParametricValue) + max * canonicParametricValue;
    values[i] = parametricValue;
  }
  return values;
}

+ (std::vector<CGFloat>)distancesForXCoordinates:(const std::vector<CGFloat> &)xCoordinates
                                    yCoordinates:(const std::vector<CGFloat> &)yCoordinates
                  minParametricValue:(CGFloat)minParametricValue {
  LTParameterAssert(xCoordinates.size() > 0, @"No x-coordinates provided");

  std::vector<CGFloat> distances(xCoordinates.size());
  distances[0] = minParametricValue;

  CGFloat sumOfDistances = minParametricValue;

  for (std::vector<CGFloat>::size_type i = 1; i < distances.size(); ++i) {
    sumOfDistances += CGPointDistance(CGPointMake(xCoordinates[i], yCoordinates[i]),
                                      CGPointMake(xCoordinates[i - 1], yCoordinates[i - 1]));
    distances[i] = sumOfDistances;
  }
  return distances;
}

@end

NS_ASSUME_NONNULL_END
