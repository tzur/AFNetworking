// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKInpaintingSuperPixel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PNKInpaintingSuperPixel

- (instancetype)initWithCoordinates:(const std::vector<cv::Point> &)coordinates {
  LTParameterAssert(!coordinates.empty(), @"Coordinates array must be non-empty");
  if (self = [super init]) {
    _center = std::accumulate(coordinates.begin(), coordinates.end(), cv::Point(0, 0)) /
        (int)coordinates.size();

    _boundingBox = cv::boundingRect(coordinates);

    std::transform(coordinates.begin(), coordinates.end(), std::back_inserter(_offsets),
                   [&](const cv::Point &point) {
      return point - _center;
    });
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
