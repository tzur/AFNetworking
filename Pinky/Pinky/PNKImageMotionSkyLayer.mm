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

  float inverseWidth = 1. / (float)_imageSize.width;
  float inverseHeight = 1. / (float)_imageSize.height;

  for (int row = 0; row < _imageSize.height; ++row) {
    auto pointerToCurrentDisplacement = (half_float::half *)displacements->ptr<cv::Vec2hf>(row);
    float yOverZ = (row - principalPoint.y) / focalLength;
    float z = skySurfaceY / (yOverZ + 1.e-6);
    float newZ = z + deltaZ;
    float focalLengthDividedByNewZ = focalLength / newZ;
    int newRow = (int)std::round(focalLengthDividedByNewZ * skySurfaceY + principalPoint.y);
    auto yDisplacement = (half_float::half)((newRow - row) * inverseHeight);
    for (int col = 0; col < _imageSize.width; ++col) {
      float xOverZ = (col - principalPoint.x) / focalLength;
      float x = xOverZ * z;
      float newX = x + deltaX;
      int newCol = (int)std::round(focalLengthDividedByNewZ * newX + principalPoint.x);
      *pointerToCurrentDisplacement++ = (half_float::half)((newCol - col) * inverseWidth);

      *pointerToCurrentDisplacement++ = yDisplacement;
    }
  }
}

@end

NS_ASSUME_NONNULL_END
