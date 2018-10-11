// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKInpaintingImageResize.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk_inpainting {

static cv::Size nextLevelSize(const cv::Size &currentLevelSize, const cv::Size &finalLevelSize) {
  if (currentLevelSize.width < finalLevelSize.width / 3) {
    return currentLevelSize * 2;
  } else if (currentLevelSize.width > finalLevelSize.width * 3) {
    return currentLevelSize / 2;
  } else {
    return finalLevelSize;
  }
}

static cv::Mat resizeImageByPyramid(const cv::Mat &source, cv::Size size, int interpolation,
                                    BOOL doGaussianBlur) {
  BOOL blurBeforeResize = doGaussianBlur && (source.cols > size.width);

  cv::Mat currentImage = blurBeforeResize ? source.clone() : source;
  while (currentImage.size() != size) {
    cv::Size nextSize = nextLevelSize(currentImage.size(), size);

    if (blurBeforeResize) {
      float sizeRatio = std::max((float)nextSize.width / currentImage.cols,
                                 (float)nextSize.height / currentImage.rows);
      double sigma = (1 / sizeRatio - 1) / 2;
      cv::GaussianBlur(currentImage, currentImage, cv::Size(0, 0), sigma);
    }

    cv::Mat nextImage;
    cv::resize(currentImage, nextImage, nextSize, 0, 0, interpolation);

    currentImage = nextImage;
  }

  return currentImage;
}

cv::Mat resizeMask(const cv::Mat &mask, cv::Size size) {
  return resizeImageByPyramid(mask, size, cv::INTER_NEAREST, NO);
}

cv::Mat resizeImage(const cv::Mat &image, cv::Size size) {
  return resizeImageByPyramid(image, size, cv::INTER_LINEAR, YES);
}

} // namespace pnk_inpainting

NS_ASSUME_NONNULL_END
