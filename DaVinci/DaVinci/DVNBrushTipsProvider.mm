// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNBrushTipsProvider.h"

#import <LTEngine/LTGLTexture.h>
#import <LTEngine/LTMathUtils.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <LTEngine/LTTexture+Factory.h>

NS_ASSUME_NONNULL_BEGIN

@implementation DVNBrushTipsProvider

const CGFloat kRoundTipGaussianSigma = 0.3;

- (LTGLTexture *)roundTipWithDimension:(NSUInteger)dimension hardness:(CGFloat)hardness {
  LTParameterAssert(LTIsPowerOfTwo(dimension), @"Provided dimension must be power of two, got: %lu",
                    dimension);
  LTParameterAssert(dimension >= 16, @"Provided dimension must greater or equal to 16, got: %lu",
                    dimension);
  LTParameterAssert(hardness >= 0 && hardness <= 1,
                    @"Provided hardness must be in range [0, 1], got: %g", hardness);
  Matrices levels;

  for (NSUInteger running = dimension; running >= 16; running /= 2) {
    levels.push_back(DVNRoundTipMat(running, kRoundTipGaussianSigma, hardness));
  }
  LTGLTexture *texture = [LTGLTexture textureWithMipmapImages:levels];
  texture.minFilterInterpolation = LTTextureInterpolationLinearMipmapLinear;
  texture.magFilterInterpolation = LTTextureInterpolationLinear;
  return texture;
}

static const cv::Mat DVNRoundTipMat(NSUInteger diameter, CGFloat sigma, CGFloat hardness) {
  cv::Mat1hf mat((uint)diameter, (uint)diameter);
  mat = half_float::half(0.0);
  int radius = mat.rows / 2 - 1;
  CGFloat inv2SigmaSquare = 1.0 / (2.0 * sigma * sigma);
  
  for (int i = 0; i < 2 * radius; ++i) {
    for (int j = 0; j < 2 * radius; ++j) {
      CGFloat y = (i - radius + 0.5) / radius;
      CGFloat x = (j - radius + 0.5) / radius;
      CGFloat squaredDistance = x * x + y * y;
      CGFloat expArgument = -squaredDistance * inv2SigmaSquare;
      CGFloat edgeFactor = 1 - MIN(1, MAX(0, (std::sqrt(squaredDistance) * radius - radius + 0.5)));
      mat(i + 1, j + 1) = half_float::half(edgeFactor * std::exp((1 - hardness) * expArgument));
    }
  }
  return mat;
}

@end

NS_ASSUME_NONNULL_END
