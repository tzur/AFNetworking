// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKInpaintingHighFrequencyTransfer.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnewline-eof"
#import <opencv2/ximgproc.hpp>
#pragma clang diagnostic pop

#import "PNKInpaintingImageResize.h"
#import "PNKInpaintingSuperPixel.h"

NS_ASSUME_NONNULL_BEGIN

/// Resolution of the distance map used to build the distance-dependent guesses distribution.
static const int kDistanceResolution = 128;

namespace pnk_inpainting {

/// Structure that stores data relevant for high frequency transfer.
struct ImageLevel {
  /// Source image.
  cv::Mat4f image;

  /// Mask of the hole to be filled.
  cv::Mat1b mask;

  /// Image with restored high frequency component of the hole.
  cv::Mat4f restoredImage;

  /// Array of superpixels covering the hole.
  std::vector<SuperPixel> superPixels;
};

/// Structure that stores data used for generating guesses for source superpixel centers.
struct GuessGeneratorData {
  /// RNG object that generates guesses.
  cv::RNG randomNumberGenerator;

  /// Distribution to produce random guesses. Its size is
  /// <tt>(kDistanceResolution, kDistanceResolution)</tt>
  cv::Mat1f cumulativeDistribution;

  /// Multiplicative factor to be applied on a point generated from \c cumulativeDistribution.
  cv::Size2f sizeFactor;
};

static cv::Mat1i segmentationMap(const cv::Mat &image, const cv::Mat1b &mask);
static std::vector<SuperPixel> superPixelsFromMap(const cv::Mat1i &map);
static cv::Mat1i resizeSegmentationMapToMaskSize(const cv::Mat1i &map, const cv::Mat1b &mask);
static void fixSegmentationMap(cv::Mat1i *map, const cv::Mat1b &mask);
static cv::Mat4f sharpenWithinMask(const cv::Mat4f &image, const cv::Mat1b &mask);
static void transferHighFrequencyBetweenLevels(ImageLevel &coarseLevel, ImageLevel &fineLevel);
static GuessGeneratorData guessGeneratorData(const cv::Mat1b &mask);
static cv::Mat1f probabilityDensity(const cv::Mat1b &mask);
static cv::Point bestMatchCenter(const SuperPixel &superPixel, const cv::Mat4f &source,
                                 const cv::Mat4f &destination, const cv::Mat1b &validMask,
                                 GuessGeneratorData &guessGeneratorData);
static cv::Point generateGuess(GuessGeneratorData &guessGeneratorData);
static bool updateMatrixSizeAndFillWithPixelValues(cv::Mat *mat, const cv::Mat &image,
                                                   const cv::Mat1b &validMask,
                                                   const SuperPixel &superPixel);
static float scoreForGuess(cv::Point guessCenter, const cv::Mat4f &guessValues,
                           cv::Point referenceCenter, const cv::Mat4f &referenceValues,
                           cv::Scalar referenceMean, cv::Scalar referenceVariance,
                           const cv::Mat4f &referenceDeviation, cv::Size imageSize);
static float calculateSSIMScore(const cv::Mat4f &guessValues, cv::Scalar referenceMean,
                                cv::Scalar referenceVariance,
                                const cv::Mat4f &referenceDeviation);
static void addImageSuperpixelValues(const cv::Mat4f &sourceImage, cv::Point sourceSuperpixelCenter,
                                     cv::Mat4f *destinationImage,
                                     const SuperPixel &destinationSuperpixel);

void transferHighFrequency(const cv::Mat4b &input, const cv::Mat1b &mask,
                           const cv::Mat4b &lowFrequency, cv::Mat4b *output) {
  LTParameterAssert(mask.rows == input.rows, @"mask matrix must have the same row count as input "
                    "matrix, got (%d, %d)", mask.rows, input.rows);
  LTParameterAssert(mask.cols == input.cols, @"mask matrix must have the same cloumn count as "
                    "input matrix, got (%d, %d)", mask.rows, input.rows);
  LTParameterAssert(lowFrequency.rows <= input.rows, @"low frequency matrix size must be lower "
                    "than or equal to input matrix size (%d), got %d", input.rows,
                    lowFrequency.rows);
  LTParameterAssert(cv::countNonZero(mask), @"mask matrix must contain at least one non-zero "
                    "pixel");

  auto fineSize = input.size();
  auto coarseSize = lowFrequency.size();

  cv::Mat4f fineImage;
  input.convertTo(fineImage, CV_32FC4, 1. / 255.);
  auto fineMask = mask;

  cv::Mat4f coarseRestoredImage;
  lowFrequency.convertTo(coarseRestoredImage, CV_32FC4, 1. / 255.);

  auto coarseImage = resizeImage(fineImage, coarseSize);
  auto coarseMask = resizeMask(mask, coarseSize);
  auto coarseSegmentationMap = segmentationMap(coarseRestoredImage, coarseMask);
  auto coarseSuperPixels = superPixelsFromMap(coarseSegmentationMap);

  ImageLevel coarseLevel = {
    .image = coarseImage,
    .mask = coarseMask,
    .restoredImage = coarseRestoredImage,
    .superPixels = coarseSuperPixels
  };

  cv::Mat4f fineLaplassianImage = fineImage - resizeImage(coarseImage, fineSize);
  auto fineSegmentationMap = resizeSegmentationMapToMaskSize(coarseSegmentationMap, fineMask);
  auto fineSuperPixels = superPixelsFromMap(fineSegmentationMap);

  auto fineRestoredImage = resizeImage(coarseRestoredImage, fineSize);
  fineRestoredImage = sharpenWithinMask(fineRestoredImage, fineMask);

  ImageLevel fineLevel = {
    .image = fineLaplassianImage,
    .mask = fineMask,
    .restoredImage = fineRestoredImage,
    .superPixels = fineSuperPixels
  };

  transferHighFrequencyBetweenLevels(coarseLevel, fineLevel);

  fineLevel.restoredImage.convertTo(*output, CV_8UC4, 255.);
}

static cv::Mat1i segmentationMap(const cv::Mat &image, const cv::Mat1b &mask) {
  cv::Mat maskPoints;
  cv::findNonZero(mask, maskPoints);
  cv::Rect boundingBox = cv::boundingRect(maskPoints);

  cv::Mat1i superPixelsMap(image.size(), 0);

  /// Average segment size (in pixels) for the SLIC segmentation algorithm. This size works well
  /// with 512x512 coarse image size.
  static const int kSLICRegionSize = 10;

  /// Segment compactness factor for the SLIC segmentation algorithm.
  static const float kSLICRuler = 1;

  /// OpenCV implementation of SLIC algorithm crashes when the input image is too small. In this
  /// case we perform no segmentation and declare the whole hole a single superpixel.
  if (boundingBox.width < kSLICRegionSize / 2 || boundingBox.height < kSLICRegionSize / 2) {
    superPixelsMap(boundingBox).setTo(1, mask(boundingBox));
    return superPixelsMap;
  }

  auto croppedMask = mask(boundingBox);
  cv::Mat croppedMaskedImage;
  image(boundingBox).copyTo(croppedMaskedImage, croppedMask);

  auto slic = cv::ximgproc::createSuperpixelSLIC(croppedMaskedImage, cv::ximgproc::SLIC,
                                                 kSLICRegionSize, kSLICRuler);
  slic->iterate();

  cv::Mat1i croppedSuperPixelsMap;
  slic->getLabels(croppedSuperPixelsMap);

  croppedSuperPixelsMap = croppedSuperPixelsMap + 1;
  croppedSuperPixelsMap.copyTo(superPixelsMap(boundingBox), croppedMask);
  return superPixelsMap;
}

static std::vector<SuperPixel> superPixelsFromMap(const cv::Mat1i &map) {
  double maxSuperPixelIndex;
  cv::minMaxLoc(map, NULL, &maxSuperPixelIndex);
  auto superPixelCount = (int)maxSuperPixelIndex;

  std::vector<std::vector<cv::Point>> coordinatesPerSuperPixel(superPixelCount);
  for (int i = 0; i < map.rows; ++i) {
    for (int j = 0; j < map.cols; ++j) {
      int superPixelIndex = map(i, j);
      if (superPixelIndex > 0) {
        coordinatesPerSuperPixel[superPixelIndex - 1].push_back(cv::Point(j, i));
      }
    }
  }

  std::vector<SuperPixel> superPixels;

  for (auto coordinates: coordinatesPerSuperPixel) {
    if (coordinates.empty()) {
      continue;
    }
    superPixels.push_back(coordinates);
  }
  return superPixels;
}

static cv::Mat1i resizeSegmentationMapToMaskSize(const cv::Mat1i &map, const cv::Mat1b &mask) {
  cv::Mat1i resizedMap = resizeMask(map, mask.size());
  fixSegmentationMap(&resizedMap, mask);
  return resizedMap;
}

static void fixSegmentationMap(cv::Mat1i *map, const cv::Mat1b &mask) {
  std::vector<std::pair<cv::Point, int>> fixes;
  int maxRadius = std::min(map->rows, map->cols) / 2;

  for (int row = 0; row < map->rows; ++row) {
    for (int col = 0; col < map->cols; ++col) {
      if (!mask(row, col)) {
        map->at<int>(row, col) = 0;
        continue;
      }

      if (map->at<int>(row, col)) {
        continue;
      }

      int nearestNeighbor = 0;
      int radius = 1;
      while (!nearestNeighbor && radius <= maxRadius) {
        for (int newRow = std::max(row - radius, 0);
             newRow <= std::min(row + radius, map->rows - 1) && !nearestNeighbor; ++newRow) {
          for (int newCol = std::max(col - radius, 0);
               newCol <= std::min(col + radius, map->cols - 1) && !nearestNeighbor; ++newCol) {
            if (map->at<int>(newRow, newCol) && mask(newRow, newCol)) {
              nearestNeighbor = map->at<int>(newRow, newCol);
            }
          }
        }
        ++radius;
      }

      if (nearestNeighbor) {
        fixes.push_back(std::make_pair(cv::Point(col, row), nearestNeighbor));
      }
    }
  }

  for (auto fix: fixes) {
    map->at<int>(fix.first.y, fix.first.x) = fix.second;
  }
}

static cv::Mat4f sharpenWithinMask(const cv::Mat4f &image, const cv::Mat1b &mask) {
  cv::Mat maskPoints;
  cv::findNonZero(mask, maskPoints);

  auto boundingBox = cv::boundingRect(maskPoints);

  auto croppedImage = image(boundingBox);

  cv::Mat3f croppedImageRGB;
  cv::cvtColor(croppedImage, croppedImageRGB, cv::COLOR_RGBA2RGB);

  cv::Mat3f croppedImageRGBFiltered;

  /// Color Sigma parameter for bilateral filter.
  static float kSigmaColor = 1;

  /// Spatial Sigma parameter for bilateral filter.
  static float kSigmaSpatial = 1;

  cv::bilateralFilter(croppedImageRGB, croppedImageRGBFiltered, 0, kSigmaColor, kSigmaSpatial);

  cv::Mat4f croppedImageFiltered;
  cv::cvtColor(croppedImageRGBFiltered, croppedImageFiltered, cv::COLOR_RGB2RGBA);

  cv::Mat4f croppedImageLaplacian;
  cv::Laplacian(croppedImageFiltered, croppedImageLaplacian, CV_32FC4);

  cv::Mat4f croppedMaskedImageLaplacian(croppedImageLaplacian.size(), cv::Scalar::all(0));
  croppedImageLaplacian.copyTo(croppedMaskedImageLaplacian, mask(boundingBox));

  auto result = image.clone();

  /// Weight of the Laplace operator output.
  static float kEdgesLaplaceIntensity = 0.25;

  result(boundingBox) += kEdgesLaplaceIntensity * croppedMaskedImageLaplacian;
  return result;
}

static void transferHighFrequencyBetweenLevels(ImageLevel &coarseLevel, ImageLevel &fineLevel) {
  float sizeRatio = (float)fineLevel.image.cols / coarseLevel.image.cols;
  auto originalPixelsMask = (coarseLevel.mask == 0);

  auto dataForGuessGeneration = guessGeneratorData(coarseLevel.mask);

  LTAssert(coarseLevel.superPixels.size() == fineLevel.superPixels.size(), @"Coarse level and fine "
           "level must have the same number of superpixels, got %lu and %lu",
           coarseLevel.superPixels.size(), fineLevel.superPixels.size());
  for (size_t i = 0; i < coarseLevel.superPixels.size(); ++i) {
    auto sourceSuperPixel = coarseLevel.superPixels[i];
    auto destinationSuperPixel = fineLevel.superPixels[i];

    auto matchCenter = bestMatchCenter(sourceSuperPixel, coarseLevel.image,
                                       coarseLevel.restoredImage, originalPixelsMask,
                                       dataForGuessGeneration);
    matchCenter *= sizeRatio;

    addImageSuperpixelValues(fineLevel.image, matchCenter, &fineLevel.restoredImage,
                             destinationSuperPixel);
  }

  cv::threshold(fineLevel.restoredImage, fineLevel.restoredImage, 1, 1, cv::THRESH_TRUNC);
  cv::threshold(fineLevel.restoredImage, fineLevel.restoredImage, 0, 0, cv::THRESH_TOZERO);

  // <tt>fineLevel.image</tt> contained the high-frequency component of the restored image.
  // Here the low-frequency component is added.
  fineLevel.image += resizeImage(coarseLevel.image, fineLevel.image.size());
  fineLevel.image.copyTo(fineLevel.restoredImage, fineLevel.mask == 0);
}

static GuessGeneratorData guessGeneratorData(const cv::Mat1b &mask) {
  auto density = probabilityDensity(mask);
  auto cumulativeDistribution = cv::Mat1f(density.size());
  std::partial_sum(density.begin(), density.end(), cumulativeDistribution.begin());

  return {
    .randomNumberGenerator = cv::RNG(0),
    .cumulativeDistribution = cumulativeDistribution,
    .sizeFactor = cv::Size2f((float)mask.cols / kDistanceResolution,
                             (float)mask.rows / kDistanceResolution)
  };
}

static cv::Mat1f probabilityDensity(const cv::Mat1b &mask) {
  cv::Mat1b complementaryMask = (mask == 0);

  cv::Size distanceMapSize(kDistanceResolution, kDistanceResolution);
  auto resizedComplementaryMask = resizeMask(complementaryMask, distanceMapSize);

  cv::Mat1f maskDistance;
  cv::distanceTransform(resizedComplementaryMask, maskDistance, cv::DIST_L2, cv::DIST_MASK_PRECISE);

  double maxMaskDistance;
  cv::minMaxLoc(maskDistance, NULL, &maxMaskDistance);
  maskDistance = maxMaskDistance - maskDistance;

  cv::Mat1f probabilityDensity(maskDistance.size(), 0);
  maskDistance.copyTo(probabilityDensity, resizedComplementaryMask);

  /// Parameter for distance-dependent guesses distribution. Higher values increase the probability
  /// of a picked guess to be closer to the hole.
  static const float kDistanceGamma = 3;

  cv::pow(probabilityDensity, kDistanceGamma, probabilityDensity);
  probabilityDensity /= cv::sum(probabilityDensity)[0];

  return probabilityDensity;
}

static cv::Point bestMatchCenter(const SuperPixel &referenceSuperPixel,
                                 const cv::Mat4f &guessSourceImage,
                                 const cv::Mat4f &referenceImage, const cv::Mat1b &validMask,
                                 GuessGeneratorData &guessGeneratorData) {
  cv::Point bestMatchCenter;
  float minScore = std::numeric_limits<float>::max();

  cv::Mat4f referenceValues;
  updateMatrixSizeAndFillWithPixelValues(&referenceValues, referenceImage, cv::Mat(),
                                         referenceSuperPixel);

  cv::Scalar referenceMean, referenceStandardDeviation;
  cv::meanStdDev(referenceValues, referenceMean, referenceStandardDeviation);
  cv::Scalar referenceVariance = referenceStandardDeviation.mul(referenceStandardDeviation);
  cv::Mat4f referenceDeviation = referenceValues - referenceMean;

  cv::Mat4f guessValues;

  /// Number of iterations for searching for nearest neighbor for each segment.
  static const int kIterationCount = 200;

  for (int i = 0; i < kIterationCount; ++i) {
    auto guess = generateGuess(guessGeneratorData);
    auto guessSuperPixel = referenceSuperPixel.centeredAt(guess);
    if (!updateMatrixSizeAndFillWithPixelValues(&guessValues, guessSourceImage, validMask,
                                                guessSuperPixel)) {
      continue;
    }

    auto score = scoreForGuess(guess, guessValues, referenceSuperPixel.center(), referenceValues,
                               referenceMean, referenceVariance, referenceDeviation,
                               guessSourceImage.size());

    if (score < minScore) {
      minScore = score;
      bestMatchCenter = guess;
    }
  }

  return bestMatchCenter;
}

static cv::Point generateGuess(GuessGeneratorData &guessGeneratorData) {
  float random = guessGeneratorData.randomNumberGenerator.uniform(0., 1.);
  auto cumulativeDistributionBegin =
      (float const *)guessGeneratorData.cumulativeDistribution.begin().ptr;
  auto cumulativeDistributionEnd =
      (float const *)guessGeneratorData.cumulativeDistribution.end().ptr;
  auto elementInDistribution = std::lower_bound(cumulativeDistributionBegin,
                                                cumulativeDistributionEnd, random);
  int index = (int)(elementInDistribution - cumulativeDistributionBegin);
  cv::Point2f guess(index % guessGeneratorData.cumulativeDistribution.cols,
                    index / guessGeneratorData.cumulativeDistribution.cols);
  guess += cv::Point2f(guessGeneratorData.randomNumberGenerator.uniform(0., 1.),
                       guessGeneratorData.randomNumberGenerator.uniform(0., 1.));
  return cv::Point(guess.x * guessGeneratorData.sizeFactor.width,
                   guess.y * guessGeneratorData.sizeFactor.height);
}

static bool updateMatrixSizeAndFillWithPixelValues(cv::Mat *mat, const cv::Mat &image,
                                                   const cv::Mat1b &validMask,
                                                   const SuperPixel &superPixel) {
  auto offsets = superPixel.offsets();
  int offsetCount = offsets.rows;
  if (mat->rows != offsetCount || mat->cols != 1 || mat->type() != image.type()) {
    mat->create(offsetCount, 1, image.type());
  }

  auto center = superPixel.center();
  bool maskIsNotEmpty = !validMask.empty();
  for (int i = 0; i < offsetCount; ++i) {
    auto point = center + (cv::Point)offsets(i);
    if (point.x < 0 || point.y < 0 || point.x >= image.cols || point.y >= image.rows ||
        (maskIsNotEmpty && !validMask(point.y, point.x))) {
      return NO;
    }
    memcpy(mat->ptr(i), image.ptr(point.y, point.x), image.elemSize());
  }

  return YES;
}

static float scoreForGuess(cv::Point guessCenter, const cv::Mat4f &guessValues,
                           cv::Point referenceCenter, const cv::Mat4f &referenceValues,
                           cv::Scalar referenceMean, cv::Scalar referenceVariance,
                           const cv::Mat4f &referenceDeviation, cv::Size imageSize) {
  float mseScore = cv::norm(guessValues, referenceValues, cv::NORM_L2SQR) /
      (3 * guessValues.rows);

  float ssimScore = calculateSSIMScore(guessValues, referenceMean, referenceVariance,
                                       referenceDeviation);

  cv::Size centerDiff = guessCenter - referenceCenter;

  float numerator = std::hypot(centerDiff.width, centerDiff.height);
  float denominator = std::sqrt(2 * imageSize.width * imageSize.height);
  float spatialScore = numerator / denominator;

  return mseScore - 0.03 * ssimScore + 0.3 * spatialScore;
}

static float calculateSSIMScore(const cv::Mat4f &guessValues, cv::Scalar referenceMean,
                                cv::Scalar referenceVariance,
                                const cv::Mat4f &referenceDeviation) {
  cv::Scalar guessMean, guessStandardDeviation;
  cv::meanStdDev(guessValues, guessMean, guessStandardDeviation);
  cv::Scalar guessVariance = guessStandardDeviation.mul(guessStandardDeviation);

  cv::Mat1f referenceDeviationSingleChannel = referenceDeviation.reshape(1);
  cv::Mat1f guessValuesSingleChannel = guessValues.reshape(1);

  cv::Scalar covariance;
  for (int i = 0; i < 3; ++i) {
    covariance[i] = guessValuesSingleChannel.col(i).dot(referenceDeviationSingleChannel.col(i));
  }

  covariance /= (float)guessValues.rows;

  const static float c1 = 1.e-4;
  const static float c2 = 9.e-4;

  float sumOfChannelScores = 0;

  for (int j = 0; j < 3; ++j) {
    float numerator = (2. * guessMean[j] * referenceMean[j] + c1) * (2. * covariance[j] + c2);
    float denominator = (guessMean[j] * guessMean[j] + referenceMean[j] * referenceMean[j] + c1) *
        (guessVariance[j] + referenceVariance[j] + c2);
    sumOfChannelScores += numerator / denominator;
  }

  return sumOfChannelScores / 3.;
}

static void addImageSuperpixelValues(const cv::Mat4f &sourceImage, cv::Point sourceSuperpixelCenter,
                                     cv::Mat4f *destinationImage,
                                     const SuperPixel &destinationSuperpixel) {
  auto destinationSuperpixelCenter = destinationSuperpixel.center();
  for (auto offset: destinationSuperpixel.offsets()) {
    auto sourcePoint = sourceSuperpixelCenter + (cv::Point)offset;
    auto destinationPoint = destinationSuperpixelCenter + (cv::Point)offset;
    destinationImage->at<cv::Vec4f>(destinationPoint.y, destinationPoint.x) +=
        sourceImage(sourcePoint.y, sourcePoint.x);
  }
}

} // namespace pnk_inpainting

NS_ASSUME_NONNULL_END
