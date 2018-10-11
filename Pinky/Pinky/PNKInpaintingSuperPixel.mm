// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKInpaintingSuperPixel.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk_inpainting {

SuperPixel::SuperPixel(const cv::Point &center, const cv::Mat2i &offsets,
                       const cv::Rect &boundingBox) :
    _center(center), _offsets(offsets), _boundingBox(boundingBox) {
}

SuperPixel::SuperPixel(const std::vector<cv::Point> &coordinates) {
  LTParameterAssert(!coordinates.empty(), @"Coordinates array must be non-empty");
  auto coordinatesMat = cv::Mat(coordinates);
  auto meanCoordinate = cv::mean(coordinatesMat);
  _center = cv::Point(std::round(meanCoordinate[0]), std::round(meanCoordinate[1]));
  _offsets = coordinatesMat - cv::Scalar(_center.x, _center.y);
  _boundingBox = cv::boundingRect(coordinates);
}

SuperPixel SuperPixel::centeredAt(const cv::Point &center) const {
  auto newBoundingBox = cv::Rect(this->boundingBox().tl() + (center - this->center()),
                                 this->boundingBox().size());
  return SuperPixel(center, this->_offsets, newBoundingBox);
}

} // namespace pnk_inpainting

NS_ASSUME_NONNULL_END
