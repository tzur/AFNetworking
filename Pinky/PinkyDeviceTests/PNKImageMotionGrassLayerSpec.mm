// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionGrassLayer.h"

#import "PNKImageMotionLayerExamples.h"

SpecBegin(PNKImageMotionGrassLayer)

itShouldBehaveLike(kPNKImageMotionLayerExamples, ^{
  // Image width.
  static const int kImageWidth = 256;
  // Image height.
  static const int kImageHeight = 128;

  auto grassLayer = [[PNKImageMotionGrassLayer alloc]
                     initWithImageSize:cv::Size(kImageWidth, kImageHeight) patchSize:32
                     amplitude:1];

  return @{
    kPNKImageMotionLayerExamplesLayer: grassLayer,
    kPNKImageMotionLayerExamplesImageWidth: @(kImageWidth),
    kPNKImageMotionLayerExamplesImageHeight: @(kImageHeight)
  };
});

itShouldBehaveLike(kPNKImageMotionLayerExamples, ^{
  // Image width.
  static const int kImageWidth = 255;
  // Image height.
  static const int kImageHeight = 129;

  auto grassLayer = [[PNKImageMotionGrassLayer alloc]
                     initWithImageSize:cv::Size(kImageWidth, kImageHeight) patchSize:32
                     amplitude:1];

  return @{
    kPNKImageMotionLayerExamplesLayer: grassLayer,
    kPNKImageMotionLayerExamplesImageWidth: @(kImageWidth),
    kPNKImageMotionLayerExamplesImageHeight: @(kImageHeight)
  };
});

SpecEnd
