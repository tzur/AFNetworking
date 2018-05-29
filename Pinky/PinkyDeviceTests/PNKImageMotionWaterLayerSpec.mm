// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionWaterLayer.h"

#import "PNKImageMotionLayerExamples.h"

SpecBegin(PNKImageMotionWaterLayer)

// Image width.
static const int kImageWidth = 256;
// Image height.
static const int kImageHeight = 128;

__block PNKImageMotionWaterLayer *waterLayer;

beforeEach(^{
  waterLayer = [[PNKImageMotionWaterLayer alloc]
                initWithImageSize:cv::Size(kImageWidth, kImageHeight) patchSize:32 amplitude:1];
});

itShouldBehaveLike(kPNKImageMotionLayerExamples, ^{
  return @{
    kPNKImageMotionLayerExamplesLayer: waterLayer,
    kPNKImageMotionLayerExamplesImageWidth: @(kImageWidth),
    kPNKImageMotionLayerExamplesImageHeight: @(kImageHeight)
  };
});

SpecEnd
