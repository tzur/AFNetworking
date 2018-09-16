// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionGrassLayer.h"

#import "PNKImageMotionLayerUtils.h"
#import "PNKImageMotionWavePatch.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKImageMotionGrassLayer ()

/// Wave patch object for simulating displacements along X axis.
@property (readonly, nonatomic) PNKImageMotionWavePatch *wavePatchX;

/// Wave patch object for simulating displacements along Y axis.
@property (readonly, nonatomic) PNKImageMotionWavePatch *wavePatchY;

/// Waves amplitude.
@property (readonly, nonatomic) CGFloat amplitude;

/// Patch size.
@property (readonly, nonatomic) NSUInteger patchSize;

@end

@implementation PNKImageMotionGrassLayer

@synthesize imageSize = _imageSize;

- (instancetype)initWithImageSize:(cv::Size)imageSize patchSize:(NSUInteger)patchSize
                        amplitude:(CGFloat)amplitude {
  if (self = [super init]) {
    _imageSize = imageSize;
    _patchSize = patchSize;
    _wavePatchX = [[PNKImageMotionWavePatch alloc] initWithPatchSize:patchSize];
    _wavePatchY = [[PNKImageMotionWavePatch alloc] initWithPatchSize:patchSize];
    _amplitude = amplitude;
  }
  return self;
}

- (void)displacements:(cv::Mat *)displacements forTime:(NSTimeInterval)time {
  PNKImageMotionValidateDisplacementsMatrix(*displacements, self.imageSize);

  cv::Mat1f patchDisplacementsX = [self.wavePatchX displacementsForTime:time];
  cv::Mat1f patchDisplacementsY = [self.wavePatchY displacementsForTime:time];

  for (int row = 0; row < displacements->rows; ++row) {
    auto pointerToCurrentDisplacement = (half_float::half *)displacements->ptr<cv::Vec2hf>(row);
    float perspectiveCoefficient = (float)row / (float)displacements->rows;
    float adjustedAmplitudeX = _amplitude * perspectiveCoefficient;
    float adjustedAmplitudeY = adjustedAmplitudeX / 6;
    int rowInPatch = row % _patchSize;
    int colInPatch = 0;
    for (int col = 0; col < displacements->cols; ++col) {
      *pointerToCurrentDisplacement++ =
          (half_float::half)(adjustedAmplitudeX * patchDisplacementsX(rowInPatch, colInPatch));

      *pointerToCurrentDisplacement++ =
          (half_float::half)(adjustedAmplitudeY * patchDisplacementsY(rowInPatch, colInPatch));

      colInPatch++;
      if (colInPatch == (int)_patchSize) {
        colInPatch = 0;
      }
    }
  }
}

@end

NS_ASSUME_NONNULL_END
