// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionSkyLayer.h"

#import "PNKImageMotionLayerUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKImageMotionSkyLayer ()

/// X-component of the wind velocity vector. The wind velocity is assumed to belong to the XZ plane.
@property (readonly, nonatomic) CGFloat velocityX;

/// Z-component of the wind velocity vector.
@property (readonly, nonatomic) CGFloat velocityZ;

@end

@implementation PNKImageMotionSkyLayer

@synthesize imageSize = _imageSize;

- (instancetype)initWithImageSize:(cv::Size)imageSize angle:(CGFloat)angle speed:(CGFloat)speed {
  if (self = [super init]) {
    _imageSize = imageSize;
    _velocityX = speed * std::cos((angle / 360.0) * 2 * M_PI);
    _velocityZ = speed * std::sin((angle / 360.0) * 2 * M_PI);
  }
  return self;
}

- (void)displacements:(cv::Mat *)displacements forTime:(NSTimeInterval)time {
  PNKImageMotionValidateDisplacementsMatrix(*displacements, self.imageSize);

  float focalLength = 0.5 * std::max(displacements->rows, displacements->cols);
  float skySurfaceY = -0.5 * displacements->rows;
  CGPoint principalPoint = CGPointMake(0.5 * displacements->cols, 0.5 * displacements->rows);

  float deltaX = self.velocityX * time;
  float deltaZ = self.velocityZ * time;

  for (int row = 0; row < self.imageSize.height; ++row) {
    for (int col = 0; col < self.imageSize.width; ++col) {
      float xOverZ = (col - principalPoint.x) / focalLength;
      float yOverZ = (row - principalPoint.y) / focalLength;
      float z = skySurfaceY / (yOverZ + 1.e-6);
      float x = xOverZ * z;
      float newX = x + deltaX;
      float newZ = z + deltaZ;
      int newCol = (int)std::round((focalLength / newZ) * newX + principalPoint.x);
      int newRow = (int)std::round((focalLength / newZ) * skySurfaceY + principalPoint.y);
      displacements->at<cv::Vec2hf>(row, col)[0] = (half_float::half)(newCol - col) /
          (half_float::half)self.imageSize.width;
      displacements->at<cv::Vec2hf>(row, col)[1] = (half_float::half)(newRow - row) /
          (half_float::half)self.imageSize.height;
    }
  }
}

@end

NS_ASSUME_NONNULL_END
