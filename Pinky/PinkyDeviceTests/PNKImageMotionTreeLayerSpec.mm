// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionTreeLayer.h"

#import "PNKImageMotionLayerExamples.h"
#import "PNKImageMotionLayerType.h"

SpecBegin(PNKImageMotionTreeLayer)

/// Image width.
static const int kImageWidth = 256;

/// Image height.
static const int kImageHeight = 128;

/// Number of samples.
static const NSUInteger kNumberOfSamples = 32;

/// Amplitude.
static const CGFloat kAmplitude = 1;

itShouldBehaveLike(kPNKImageMotionLayerExamples, ^{
  cv::Mat1b segmentation(kImageHeight, kImageWidth, (uchar)0);
  segmentation(cv::Rect(kImageWidth / 8, 0, kImageWidth / 4, kImageHeight)) =
      pnk::ImageMotionLayerTypeTrees;
  segmentation(cv::Rect(kImageWidth * 5 / 8, 0, kImageWidth / 4, kImageHeight)) =
      pnk::ImageMotionLayerTypeTrees;

  auto treeLayer = [[PNKImageMotionTreeLayer alloc]
                    initWithImageSize:cv::Size(kImageWidth, kImageHeight)
                    numberOfSamples:kNumberOfSamples amplitude:kAmplitude];
  treeLayer.segmentation = segmentation;

  return @{
    kPNKImageMotionLayerExamplesLayer: treeLayer,
    kPNKImageMotionLayerExamplesImageWidth: @(kImageWidth),
    kPNKImageMotionLayerExamplesImageHeight: @(kImageHeight)
  };
});

it(@"should raise when number of samples is not a power of 2", ^{
  expect(^{
    auto __unused treeLayer = [[PNKImageMotionTreeLayer alloc]
                               initWithImageSize:cv::Size(kImageWidth, kImageHeight)
                               numberOfSamples:kNumberOfSamples - 1 amplitude:kAmplitude];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise when segmentation width differs from image width", ^{
  auto treeLayer = [[PNKImageMotionTreeLayer alloc]
                    initWithImageSize:cv::Size(kImageWidth, kImageHeight)
                    numberOfSamples:kNumberOfSamples amplitude:kAmplitude];
  cv::Mat1b segmentation(kImageHeight, kImageWidth + 1, (uchar)0);
  expect(^{
    treeLayer.segmentation = segmentation;
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise when segmentation height differs from image height", ^{
  auto treeLayer = [[PNKImageMotionTreeLayer alloc]
                    initWithImageSize:cv::Size(kImageWidth, kImageHeight)
                    numberOfSamples:kNumberOfSamples amplitude:kAmplitude];
  cv::Mat1b segmentation(kImageHeight + 1, kImageWidth, (uchar)0);
  expect(^{
    treeLayer.segmentation = segmentation;
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise when trying to get displacements without setting segmentation", ^{
  auto treeLayer = [[PNKImageMotionTreeLayer alloc]
                    initWithImageSize:cv::Size(kImageWidth, kImageHeight)
                    numberOfSamples:kNumberOfSamples amplitude:kAmplitude];

  __block cv::Mat1hf displacements(kImageHeight, kImageWidth);
  expect(^{
    [treeLayer displacements:&displacements forTime:0];
  }).to.raise(NSInternalInconsistencyException);
});

SpecEnd
