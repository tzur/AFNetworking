// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionDisplacementProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <LTEngine/LTOpenCVExtensions.h>

#import "PNKImageMotionLayerType.h"

DeviceSpecBegin(PNKImageMotionDisplacementProcessor)

it(@"should calculate displacements and new segmentation", ^{
  // Image width and height.
  static const int kSize = 256;

  cv::Mat1b segmentation(kSize, kSize);

  segmentation(cv::Rect(0, 0, kSize / 2, kSize / 2)) = pnk::ImageMotionLayerTypeSky;
  segmentation(cv::Rect(kSize / 2, 0, kSize / 2, kSize / 2)) = pnk::ImageMotionLayerTypeTrees;
  segmentation(cv::Rect(0, kSize / 2, kSize / 2, kSize / 2)) = pnk::ImageMotionLayerTypeGrass;
  segmentation(cv::Rect(kSize / 2, kSize / 2, kSize / 2, kSize / 2)) =
      pnk::ImageMotionLayerTypeWater;

  auto segmentationBuffer = LTCVPixelBufferCreate(kSize, kSize, kCVPixelFormatType_OneComponent8);
  LTCVPixelBufferImageForWriting(segmentationBuffer.get(), ^(cv::Mat * _Nonnull image) {
    segmentation.copyTo(*image);
  });

  auto displacementsProcessor = [[PNKImageMotionDisplacementProcessor alloc]
                                 initWithSegmentation:segmentationBuffer error:nil];

  auto outputDisplacementBuffer = LTCVPixelBufferCreate(kSize, kSize,
                                                        kCVPixelFormatType_TwoComponent16Half);
  auto outputSegmentationBuffer = LTCVPixelBufferCreate(kSize, kSize,
                                                        kCVPixelFormatType_OneComponent8);

  [displacementsProcessor displacements:outputDisplacementBuffer.get()
                     andNewSegmentation:outputSegmentationBuffer.get() forTime:0.5];

  NSBundle *bundle = NSBundle.lt_testBundle;
  cv::Mat1b expectedMat = LTLoadMatFromBundle(bundle, @"multiclass_segmentation_moved.png");
  LTCVPixelBufferImageForReading(outputSegmentationBuffer.get(), ^(const cv::Mat & image) {
    expect($(image)).to.beCloseToMatNormalizedHamming($(expectedMat), 0.01);
  });
});

DeviceSpecEnd
