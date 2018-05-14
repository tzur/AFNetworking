// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionStaticLayer.h"

SpecBegin(PNKImageMotionStaticLayer)

// Image width.
static const int kImageWidth = 128;
// Image height.
static const int kImageHeight = 128;

__block PNKImageMotionStaticLayer *staticLayer;

beforeEach(^{
  staticLayer = [[PNKImageMotionStaticLayer alloc]
                 initWithImageSize:cv::Size(kImageHeight, kImageWidth)];
});

it(@"should return the same image size as passed through initializer", ^{
  auto imageSize = staticLayer.imageSize;
  expect(imageSize.width).to.equal(kImageWidth);
  expect(imageSize.height).to.equal(kImageHeight);
});

it(@"should fill displacements matrix with zeroes", ^{
  cv::Mat2hf displacements(kImageHeight, kImageWidth);
  [staticLayer displacements:&displacements forTime:1.5];

  cv::Mat2hf expectedDisplacements(kImageWidth, kImageHeight);
  expect($(displacements)).to.equalMat($(expectedDisplacements));
});

SpecEnd
