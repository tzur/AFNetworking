// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionTreeLayer.h"

#import "PNKImageMotionLayerExamples.h"
#import "PNKImageMotionLayerType.h"

SpecBegin(PNKImageMotionTreeLayer)

itShouldBehaveLike(kPNKImageMotionLayerExamples, ^{
  // Image width.
  static const int kImageWidth = 256;
  // Image height.
  static const int kImageHeight = 128;

  cv::Mat1b segmentation(kImageHeight, kImageWidth, (uchar)0);
  segmentation(cv::Rect(kImageWidth / 8, 0, kImageWidth / 4, kImageHeight)) =
      pnk::ImageMotionLayerTypeTrees;
  segmentation(cv::Rect(kImageWidth * 5 / 8, 0, kImageWidth / 4, kImageHeight)) =
      pnk::ImageMotionLayerTypeTrees;

  auto treeLayer = [[PNKImageMotionTreeLayer alloc] initWithSegmentation:segmentation
                                                         numberOfSamples:32 amplitude:1];

  return @{
    kPNKImageMotionLayerExamplesLayer: treeLayer,
    kPNKImageMotionLayerExamplesImageWidth: @(kImageWidth),
    kPNKImageMotionLayerExamplesImageHeight: @(kImageHeight)
  };
});

it(@"should raise when number of samples is not a power of 2", ^{
  expect(^{
    auto __unused treeLayer = [[PNKImageMotionTreeLayer alloc]
                               initWithSegmentation:cv::Mat1b(64, 64, (uchar)0) numberOfSamples:31
                               amplitude:1];
  }).to.raise(NSInvalidArgumentException);
});

SpecEnd
