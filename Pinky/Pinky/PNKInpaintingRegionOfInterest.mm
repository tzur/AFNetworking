// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKInpaintingRegionOfInterest.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk_inpainting {

MTLRegion regionOfInterestAroundHole(const cv::Mat &mask) {
  cv::Mat nonZeroPoints;
  cv::findNonZero(mask, nonZeroPoints);

  if (nonZeroPoints.empty()) {
    return MTLRegionMake3D(0, 0, 0, 0, 0, 0);
  }

  auto boundingBox = cv::boundingRect(nonZeroPoints);

  cv::Mat1b paddedMask = cv::Mat1b::zeros(boundingBox.height + 2, boundingBox.width + 2);
  mask(boundingBox).copyTo(paddedMask(cv::Rect(1, 1, boundingBox.width, boundingBox.height)));

  cv::Mat distances;
  cv::distanceTransform(paddedMask, distances, cv::DIST_L2, cv::DIST_MASK_3);
  double maxDistance;
  cv::minMaxLoc(distances, NULL, &maxDistance);

  double maskHeight = boundingBox.height;
  double maskWidth = boundingBox.width;
  double numPixels = nonZeroPoints.rows;

  int boundaryPixels = 0;
  for (int i = 0; i < nonZeroPoints.rows; ++i) {
    cv::Point point = nonZeroPoints.at<cv::Point>(i);
    if (point.x == 0 || point.x == mask.cols - 1 || point.y == 0 || point.y  == mask.rows - 1) {
      ++boundaryPixels;
    }
  }

  // The size of the region of interest is calculated here by linear regression. Coefficient were
  // obtained by offline training of linear regression using slow heuristic-based algorithm results
  // as ground truth.
  int size = (int)(5.8784971 * maxDistance + 1.1087765 * maskHeight + 1.0467703 * maskWidth -
                   2.1449772e-03 * numPixels - 7.9785836e-01 * boundaryPixels + 482.42358);
  size = std::max(size, 512);
  size = std::max(size, std::max(boundingBox.width, boundingBox.height));
  size = std::min(size, std::min(mask.cols, mask.rows));

  int halfSize = size / 2;
  size = halfSize * 2;

  auto center = 0.5 * (boundingBox.tl() + boundingBox.br());
  center.x = std::clamp(center.x, halfSize,  mask.cols - halfSize);
  center.y = std::clamp(center.y, halfSize,  mask.rows - halfSize);

  return MTLRegionMake2D(center.x - halfSize, center.y - halfSize, size, size);
}

} // namespace pnk_inpainting

NS_ASSUME_NONNULL_END
