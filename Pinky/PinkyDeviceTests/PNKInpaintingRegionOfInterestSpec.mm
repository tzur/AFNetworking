// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKInpaintingRegionOfInterest.h"

SpecBegin(PNKInpaintingRegionOfInterest)

it(@"should return whole image as ROI when image size is less than or equal to 512", ^{
  static const int kImageSize = 512;
  static const int kHoleSize = 8;

  cv::Mat1b mask(kImageSize, kImageSize, (uchar)0);
  cv::Rect hole((kImageSize - kHoleSize) / 2, (kImageSize - kHoleSize) / 2, kHoleSize, kHoleSize);
  mask(hole) = 1;

  auto roi = pnk_inpainting::regionOfInterestAroundHole(mask);
  auto expectedROI = MTLRegionMake2D(0, 0, kImageSize, kImageSize);

  expect(roi.origin.x).to.equal(expectedROI.origin.x);
  expect(roi.origin.y).to.equal(expectedROI.origin.y);
  expect(roi.size.width).to.equal(expectedROI.size.width);
  expect(roi.size.height).to.equal(expectedROI.size.height);
});

it(@"should return correct ROI when image size is bigger than 512", ^{
  static const int kImageSize = 2048;
  static const int kHoleSize = 8;

  cv::Mat1b mask(kImageSize, kImageSize, (uchar)0);
  cv::Rect hole((kImageSize - kHoleSize) / 2, (kImageSize - kHoleSize) / 2, kHoleSize, kHoleSize);
  mask(hole) = 1;

  auto roi = pnk_inpainting::regionOfInterestAroundHole(mask);
  auto expectedROI = MTLRegionMake2D(764, 764, 520, 520);

  expect(roi.origin.x).to.equal(expectedROI.origin.x);
  expect(roi.origin.y).to.equal(expectedROI.origin.y);
  expect(roi.size.width).to.equal(expectedROI.size.width);
  expect(roi.size.height).to.equal(expectedROI.size.height);
});

it(@"should not raise when the mask touches the upper-left corner", ^{
  static const int kImageSize = 512;
  static const int kHoleSize = 8;

  cv::Mat1b mask(kImageSize, kImageSize, (uchar)0);
  cv::Rect hole(0, 0, kHoleSize, kHoleSize);
  mask(hole) = 1;

  expect(^{
    __unused auto roi = pnk_inpainting::regionOfInterestAroundHole(mask);
  }).toNot.raiseAny();
});

it(@"should not raise when the mask touches the bottom-right corner", ^{
  static const int kImageSize = 512;
  static const int kHoleSize = 8;

  cv::Mat1b mask(kImageSize, kImageSize, (uchar)0);
  cv::Rect hole(kImageSize - kHoleSize, kImageSize - kHoleSize, kHoleSize, kHoleSize);
  mask(hole) = 1;

  expect(^{
    __unused auto roi = pnk_inpainting::regionOfInterestAroundHole(mask);
  }).toNot.raiseAny();
});

SpecEnd
