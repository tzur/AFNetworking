// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionSkyLayer.h"

#import <LTEngine/LTOpenCVExtensions.h>

#import "PNKImageMotionLayerExamples.h"

SpecBegin(PNKImageMotionSkyLayer)

// Image width.
static const int kImageWidth = 256;
// Image height.
static const int kImageHeight = 128;

__block PNKImageMotionSkyLayer *skyLayer;

beforeEach(^{
  skyLayer = [[PNKImageMotionSkyLayer alloc] initWithImageSize:cv::Size(kImageWidth, kImageHeight)
                                                         angle:0 speed:1];
});

itShouldBehaveLike(kPNKImageMotionLayerExamples, ^{
  return @{
    kPNKImageMotionLayerExamplesLayer: skyLayer,
    kPNKImageMotionLayerExamplesImageWidth: @(kImageWidth),
    kPNKImageMotionLayerExamplesImageHeight: @(kImageHeight)
  };
});

it(@"should generate displacements with zero Y component for wind angle 0", ^{
  cv::Mat2hf displacements(kImageHeight, kImageWidth);
  [skyLayer displacements:&displacements forTime:10];

  cv::Mat components[2];
  cv::split(displacements, components);
  cv::Mat displacementsY = components[1];

  auto expectedDisplacementsY = cv::Mat1hf::zeros(kImageHeight, kImageWidth);
  expect($(displacementsY)).to.equalMat($(expectedDisplacementsY));
});

it(@"should generate displacements with zero Y component for wind angle 180", ^{
  auto skyLayerLeft = [[PNKImageMotionSkyLayer alloc]
                       initWithImageSize:cv::Size(kImageWidth, kImageHeight) angle:180 speed:1];

  cv::Mat2hf displacements(kImageHeight, kImageWidth);
  [skyLayerLeft displacements:&displacements forTime:10];

  cv::Mat components[2];
  cv::split(displacements, components);
  cv::Mat displacementsY = components[1];

  auto expectedDisplacementsY = cv::Mat1hf::zeros(kImageHeight, kImageWidth);
  expect($(displacementsY)).to.equalMat($(expectedDisplacementsY));
});

SpecEnd
