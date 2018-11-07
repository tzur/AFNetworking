// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTMathUtils.h"

#import <numeric>

std::vector<CGFloat> LTCreateHalfGaussian(NSUInteger radius, CGFloat sigma, BOOL normalized) {
  LTParameterAssert(radius);
  LTParameterAssert(sigma > 0);

  std::vector<CGFloat> result;
  CGFloat invSqrt2SigmaPI = 1.0 / std::sqrt(2.0 * M_PI) / sigma;
  CGFloat inv2SigmaSquare = 1.0 / (2.0 * sigma * sigma);

  for (NSUInteger i = 0; i <= radius; ++i) {
    CGFloat x = (CGFloat)i - radius;
    result.push_back(invSqrt2SigmaPI * std::exp(-(x * x) * inv2SigmaSquare));
  }

  if (normalized) {
    CGFloat sum = std::accumulate(result.begin(), result.end(), 0.0);
    std::transform(result.begin(), result.end(), result.begin(), [sum](CGFloat value) {
      return value / sum;
    });
  }

  return result;
}
