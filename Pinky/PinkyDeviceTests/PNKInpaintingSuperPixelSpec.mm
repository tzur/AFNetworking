// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKInpaintingSuperPixel.h"

SpecBegin(PNKInpaintingSuperPixel)

it(@"should create segment with correct center, bounding box and offsets", ^{
  std::vector<cv::Point> coordinates = {{2, 2}, {2, 6}, {6, 2}, {6, 6}};

  cv::Point expectedCenter(4, 4);
  cv::Rect expectedBoundingBox(2, 2, 5, 5);

  std::vector<cv::Point> expectedOffsets(coordinates.size());
  std::transform(coordinates.begin(), coordinates.end(), expectedOffsets.begin(),
                 [expectedCenter](cv::Point point) {
    return point - expectedCenter;
  });

  auto superpixel = [[PNKInpaintingSuperPixel alloc] initWithCoordinates:coordinates];
  auto offsets = superpixel.offsets;

  expect($(superpixel.center == expectedCenter)).to.beTruthy();
  expect($(superpixel.boundingBox == expectedBoundingBox)).to.beTruthy();
  expect($(cv::Mat(offsets))).to.equalMat($(cv::Mat(expectedOffsets)));
});

it(@"should create segment with correct center, bounding box and offsets when center is not "
   "a pait of integersinteger", ^{
  std::vector<cv::Point> coordinates = {{0, 2}, {2, 0}, {2, 2}};

  cv::Point expectedCenter(1, 1);
  cv::Rect expectedBoundingBox(0, 0, 3, 3);

   std::vector<cv::Point> expectedOffsets(coordinates.size());
   std::transform(coordinates.begin(), coordinates.end(), expectedOffsets.begin(),
                  [expectedCenter](cv::Point point) {
     return point - expectedCenter;
   });

   auto superpixel = [[PNKInpaintingSuperPixel alloc] initWithCoordinates:coordinates];
   auto offsets = superpixel.offsets;

   expect($(superpixel.center == expectedCenter)).to.beTruthy();
   expect($(superpixel.boundingBox == expectedBoundingBox)).to.beTruthy();
   expect($(cv::Mat(offsets))).to.equalMat($(cv::Mat(expectedOffsets)));
});

SpecEnd
