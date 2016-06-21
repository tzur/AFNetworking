// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "LTGaussianConvolutionDivider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTGaussianConvolutionDivider

- (instancetype)initWithSigma:(CGFloat)sigma spatialUnit:(CGFloat)spatialUnit
                maxFilterTaps:(NSUInteger)maxFilterTaps
         gaussianEnergyFactor:(CGFloat)gaussianEnergyFactor {
  LTParameterAssert(sigma > 0, @"sigma (%g) should be strictly positive", sigma);
  LTParameterAssert(spatialUnit > 0, @"spatialUnit (%g) should be strictly positive", spatialUnit);
  LTParameterAssert(gaussianEnergyFactor > 0,
      @"gaussianEnergyFactor(%g) should be strictly positive", gaussianEnergyFactor);
  LTParameterAssert(gaussianEnergyFactor < 4, @"gaussianEnergyFactor is unpractically high");
  LTParameterAssert(maxFilterTaps % 2, @"maxFilterTaps (%lu) should be odd",
      (unsigned long)maxFilterTaps);
  LTParameterAssert(maxFilterTaps >= 3, @"maxFilterTaps (%lu) should be at least 3",
      (unsigned long)maxFilterTaps);

  if (self = [super init]) {
    NSUInteger farthestTap = (maxFilterTaps - 1) / 2;
    _maxSigmaPerIteration = spatialUnit * farthestTap / gaussianEnergyFactor;

    _iterationsRequired = std::ceil(std::pow(sigma, 2) / pow(self.maxSigmaPerIteration, 2));

    _iterationSigma = sigma / std::sqrt(self.iterationsRequired);
    LTAssert(self.iterationSigma <= self.maxSigmaPerIteration,
             @"iterationSigma should be less or equal to than maxSigmaPerIteration");

    _numberOfFilterTaps =
        2 * std::ceil(gaussianEnergyFactor * self.iterationSigma / spatialUnit) + 1;
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:
              @"<%@: %p, iterations: %lu, iterationSigma: %g, numberOfFilterTaps: %lu, "
              "maxSigmaPerIteration: %g>", [self class], self,
              (unsigned long)self.iterationsRequired, self.iterationSigma,
              (unsigned long)self.numberOfFilterTaps,
              self.maxSigmaPerIteration];
}

@end

NS_ASSUME_NONNULL_END
