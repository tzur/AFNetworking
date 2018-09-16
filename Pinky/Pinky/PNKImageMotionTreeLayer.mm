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

- (instancetype)initWithImageSize:(cv::Size)imageSize numberOfSamples:(NSUInteger)numberOfSamples
                        amplitude:(CGFloat)amplitude {
  float integralPart;
  LTParameterAssert(std::modf(std::log2(numberOfSamples), &integralPart) < 1.e-7,
                    @"numberOfSamples should be a power of 2, got: %lu",
                    (unsigned long)numberOfSamples);
  if (self = [super init]) {
    _imageSize = imageSize;
    _amplitude = amplitude;

    auto treeTipMovement = [[PNKImageMotionTreeTipMovement alloc]
                            initWithNumberOfSamples:numberOfSamples];
    _treeTipDisplacements = treeTipMovement.treeTipDisplacements;
  }
  return self;
}

- (void)updateWithSegmentationMap:(const cv::Mat1b &)segmentationMap {
  LTParameterAssert(segmentationMap.size() == self.imageSize, @"Expected segmentation map of size "
                    "(%d, %d), got (%d, %d)", self.imageSize.width, self.imageSize.height,
                    segmentationMap.cols, segmentationMap.rows);
  [self setupTreeConnectedComponentsWithSegmentation:segmentationMap];
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

  LTAssert(!_treesStatistics.empty(), @"An attempt to calculate tree layer displacements without "
           "updating the layer with a segmentation map.");

  displacements->setTo(cv::Vec2hf((half_float::half)10, (half_float::half)10));

  static const NSUInteger kFramesPerSecond = 30;
  int displacementsCount = _treeTipDisplacements.rows;
  int numberOfSamples = _treeTipDisplacements.cols;

  float timeRemainderInFrames = std::fmod(time * kFramesPerSecond, numberOfSamples);

  int firstSampleIndex = (int)timeRemainderInFrames;
  int secondSampleIndex = (firstSampleIndex < numberOfSamples - 1) ?
      (firstSampleIndex + 1) : 0;
  float interpolationCoefficient = timeRemainderInFrames - firstSampleIndex;

  float inverseWidth = 1. / (float)self.imageSize.width;
  float inverseHeight = 1. / (float)self.imageSize.height;

  for (int component = 1; component < _treesStatistics.rows; ++component) {
    int displacementsIndex = (component - 1) % displacementsCount;
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

      auto xRelativeDisplacement = (half_float::half)(-xDisplacement * inverseWidth);
      auto yRelativeDisplacement = (half_float::half)(-yDisplacement * inverseHeight);

      int newRow = std::clamp(row + std::round(yDisplacement), 0, _treesWithLabels.rows - 1);
      auto pointerToNewRow = (half_float::half *)displacements->ptr(newRow);

      for (int col = left; col < left + width; ++col) {
        if (_treesWithLabels.at<int>(row, col) != component) {
          continue;
        }

        int newCol = std::clamp(col + std::round(xDisplacement), 0, _treesWithLabels.cols - 1);

        pointerToNewRow[2 * newCol] = xRelativeDisplacement;
        pointerToNewRow[2 * newCol + 1] = yRelativeDisplacement;
      }
    }
  }
}

@end

NS_ASSUME_NONNULL_END
