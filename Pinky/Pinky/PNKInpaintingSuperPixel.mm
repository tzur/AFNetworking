// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKInpaintingSuperPixel.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PNKInpaintingSuperPixel

- (instancetype)initWithCoordinates:(const std::vector<cv::Point> &)coordinates {
  LTParameterAssert(!coordinates.empty(), @"Coordinates array must be non-empty");
  auto coordinatesMat = cv::Mat(coordinates);
  auto meanCoordinate = cv::mean(coordinatesMat);
  auto center = cv::Point(std::round(meanCoordinate[0]), std::round(meanCoordinate[1]));
  auto offsets = coordinatesMat - cv::Scalar(center.x, center.y);
  auto boundingBox = cv::boundingRect(coordinates);
  return [self initWithCenter:center offsets:offsets boundingBox:boundingBox];
}

- (instancetype)initWithCenter:(cv::Point)center offsets:(cv::Mat2i)offsets
                   boundingBox:(cv::Rect)boundingBox {
  if (self = [super init]) {
    _center = center;
    _offsets = offsets;
    _boundingBox = boundingBox;
  }
  return self;
}

- (instancetype)superPixelCenteredAt:(cv::Point)center {
  auto newBoundingBox = cv::Rect(self.boundingBox.tl() + (center - self.center),
                                 self.boundingBox.size());

  return [[PNKInpaintingSuperPixel alloc] initWithCenter:center offsets:self.offsets
                                             boundingBox:newBoundingBox];
}

@end

NS_ASSUME_NONNULL_END
