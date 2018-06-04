// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionTreeLayer.h"

#import "PNKImageMotionLayerType.h"
#import "PNKImageMotionLayerUtils.h"
#import "PNKImageMotionTreeTipMovement.h"

NS_ASSUME_NONNULL_BEGIN

@interface PNKImageMotionTreeLayer ()

/// Amplitude of tree tip oscillation.
@property (readonly, nonatomic) CGFloat amplitude;

@end

@implementation PNKImageMotionTreeLayer {
  /// Displacements of a tree tip with different random seeds.
  cv::Mat1f _treeTipDisplacements;

  /// Connected components labeled image with each tree or connected group of trees as a component.
  cv::Mat _treesWithLabels;

  /// Statistics (bounding box and pixel count) for each connected component (group of trees).
  cv::Mat _treesStatistics;
}

@synthesize imageSize = _imageSize;

- (instancetype)initWithSegmentation:(const cv::Mat &)segmentation
                     numberOfSamples:(NSUInteger)numberOfSamples
                           amplitude:(CGFloat)amplitude {
  float integralPart;
  LTParameterAssert(std::modf(std::log2(numberOfSamples), &integralPart) < 1.e-7,
                    @"numberOfSamples should be a power of 2, got: %lu",
                    (unsigned long)numberOfSamples);
  if (self = [super init]) {
    [self setupTreeConnectedComponentsWithSegmentation:segmentation];
    _imageSize = segmentation.size();
    _amplitude = amplitude;

    auto treeTipMovement = [[PNKImageMotionTreeTipMovement alloc]
                            initWithNumberOfSamples:numberOfSamples];
    _treeTipDisplacements = treeTipMovement.treeTipDisplacements;
  }
  return self;
}

- (void)setupTreeConnectedComponentsWithSegmentation:(const cv::Mat &)segmentation {
  static const int kErosionSize = 10;
  static const int kDilationSize = 15;

  cv::Mat treeMask = (segmentation == pnk::ImageMotionLayerTypeTrees);

  cv::Mat extendedTreeMask;
  cv::erode(treeMask, extendedTreeMask, cv::Mat(), cv::Point(-1, -1), kErosionSize);
  cv::dilate(extendedTreeMask, extendedTreeMask, cv::Mat(), cv::Point(-1, -1), kDilationSize);

  cv::Mat centroids;
  cv::connectedComponentsWithStats(extendedTreeMask, _treesWithLabels, _treesStatistics, centroids);
}

- (void)displacements:(cv::Mat *)displacements forTime:(NSTimeInterval)time {
  PNKImageMotionValidateDisplacementsMatrix(*displacements, self.imageSize);

  *displacements = 0;

  static const NSUInteger kFramesPerSecond = 30;
  int displacementsCount = _treeTipDisplacements.rows;
  int numberOfSamples = _treeTipDisplacements.cols;

  float timeRemainderInFrames = std::fmod(time * kFramesPerSecond, numberOfSamples);

  int firstSampleIndex = (int)timeRemainderInFrames;
  int secondSampleIndex = (firstSampleIndex < numberOfSamples - 1) ?
      (firstSampleIndex + 1) : 0;
  float interpolationCoefficient = firstSampleIndex - timeRemainderInFrames;

  for (int component = 1; component < _treesStatistics.rows; ++component) {
    int displacementsIndex = component % displacementsCount;
    float tipDisplacement = _treeTipDisplacements(displacementsIndex, firstSampleIndex) *
        (1 - interpolationCoefficient) +
        _treeTipDisplacements(displacementsIndex, secondSampleIndex) * interpolationCoefficient;
    tipDisplacement *= self.amplitude;

    int left = _treesStatistics.at<int>(component, cv::CC_STAT_LEFT);
    int top = _treesStatistics.at<int>(component, cv::CC_STAT_TOP);
    int width = _treesStatistics.at<int>(component, cv::CC_STAT_WIDTH);
    int height = _treesStatistics.at<int>(component, cv::CC_STAT_HEIGHT);

    for (int row = top; row < top + height; ++row) {
      float heightAboveGround = top + height - row - 1;
      float relativeHeightAboveGround = heightAboveGround / ((float)height - 1);
      float relativeAngle = (1. / 3.) * std::pow(relativeHeightAboveGround, 4) -
          (4. / 3.) * std::pow(relativeHeightAboveGround, 3) +
          2 * std::pow(relativeHeightAboveGround, 2);

      float angle = tipDisplacement * relativeAngle;
      float xDisplacement = std::sin(angle) * heightAboveGround;
      float yDisplacement = (1 - std::cos(angle)) * heightAboveGround;

      for (int col = left; col < left + width; ++col) {
        if(_treesWithLabels.at<int>(row, col) != component) {
          continue;
        }

        int newCol = std::clamp(col + std::round(xDisplacement), 0, _treesWithLabels.cols - 1);
        int newRow = std::clamp(row + std::round(yDisplacement), 0, _treesWithLabels.rows - 1);

        displacements->at<cv::Vec2hf>(newRow, newCol)[0] = -(half_float::half)xDisplacement /
            (half_float::half)displacements->cols;
        displacements->at<cv::Vec2hf>(newRow, newCol)[1] = -(half_float::half)yDisplacement /
            (half_float::half)displacements->rows;
      }
    }
  }
}

@end

NS_ASSUME_NONNULL_END
