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

  for (int row = 0; row < displacements->rows; ++row) {
    for (int col = 0; col < displacements->cols; ++col) {
      float xOverZ = (col - principalPoint.x) / focalLength;
      float yOverZ = (row - principalPoint.y) / focalLength;
      float z = waterSurfaceY / (yOverZ + 1.e-6);
      float x = xOverZ * z;
      int patchX = (int)std::round(x) % patchDisplacements.cols;
      int patchZ = (int)std::round(z) % patchDisplacements.rows;
      float newY = waterSurfaceY + self.amplitude * patchDisplacements(patchZ, patchX);
      int newRow = (focalLength / z) * newY + principalPoint.y;
      displacements->at<cv::Vec2hf>(row, col)[0] = 0;
      displacements->at<cv::Vec2hf>(row, col)[1] = (half_float::half)(newRow - row) /
          (half_float::half)displacements->rows;
    }
  }
}

@end

NS_ASSUME_NONNULL_END
