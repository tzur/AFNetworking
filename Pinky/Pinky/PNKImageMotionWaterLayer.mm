// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionWaterLayer.h"

#import "PNKImageMotionLayerUtils.h"
#import "PNKImageMotionWavePatch.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKImageMotionWaterLayer ()

/// Wave patch object.
@property (readonly, nonatomic) PNKImageMotionWavePatch *wavePatch;

/// Waves amplitude.
@property (readonly, nonatomic) CGFloat amplitude;

@end

@implementation PNKImageMotionWaterLayer

@synthesize imageSize = _imageSize;

- (instancetype)initWithImageSize:(cv::Size)imageSize patchSize:(NSUInteger)patchSize
                        amplitude:(CGFloat)amplitude {
  if (self = [super init]) {
    _imageSize = imageSize;
    _wavePatch = [[PNKImageMotionWavePatch alloc] initWithPatchSize:patchSize];
    _amplitude = amplitude;
  }
  return self;
}

- (void)displacements:(cv::Mat *)displacements forTime:(NSTimeInterval)time {
  PNKImageMotionValidateDisplacementsMatrix(*displacements, self.imageSize);

  float focalLength = 0.5 * std::max(displacements->rows, displacements->cols);
  float waterSurfaceY = 0.5 * focalLength;
  CGPoint principalPoint = CGPointMake(0.5 * displacements->cols, 0.5 * displacements->rows);

  cv::Mat1f patchDisplacements = [self.wavePatch displacementsForTime:time];

  float inverseHeight = 1. / (float)self.imageSize.height;
  float inverseFocalLength = 1. / focalLength;

  for (int row = 0; row < displacements->rows; ++row) {
    auto pointerToCurrentDisplacement = (half_float::half *)displacements->ptr<cv::Vec2hf>(row);
    float yOverZ = (row - principalPoint.y) * inverseFocalLength;
    float z = waterSurfaceY / (yOverZ + 1.e-6);
    int patchZ = (int)std::round(z) % patchDisplacements.rows;
    for (int col = 0; col < displacements->cols; ++col) {
      float xOverZ = (col - principalPoint.x) * inverseFocalLength;
      float x = xOverZ * z;
      int patchX = (int)std::round(x) % patchDisplacements.cols;
      float newY = waterSurfaceY + _amplitude * patchDisplacements(patchZ, patchX);
      int newRow = (focalLength / z) * newY + principalPoint.y;

      *pointerToCurrentDisplacement++ = 0;
      *pointerToCurrentDisplacement++ = (half_float::half)((newRow - row) * inverseHeight);
    }
  }
}

@end

NS_ASSUME_NONNULL_END
