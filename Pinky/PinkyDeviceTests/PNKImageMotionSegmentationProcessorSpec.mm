// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionSegmentationProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

DeviceSpecBegin(PNKImageMotionSegmentationProcessor)

context(@"segment", ^{
  it(@"should segment RGBA image correctly", ^{
    NSBundle *bundle = NSBundle.lt_testBundle;
    NSError *error;
    auto networkModelURL =
        [NSURL URLWithString:[bundle lt_pathForResource:@"multiclass_segmentation.nnmodel"]];
    auto processor = [[PNKImageMotionSegmentationProcessor alloc]
                      initWithNetworkModel:networkModelURL error:&error];
    cv::Mat4b inputMat = LTLoadMatFromBundle(bundle, @"tree.png");

    auto inputBuffer = LTCVPixelBufferCreate(inputMat.cols, inputMat.rows,
                                             kCVPixelFormatType_32BGRA);
    LTCVPixelBufferImageForWriting(inputBuffer.get(), ^(cv::Mat * _Nonnull image) {
      inputMat.copyTo(*image);
    });

    auto outputBuffer = LTCVPixelBufferCreate(inputMat.cols, inputMat.rows,
                                              kCVPixelFormatType_OneComponent8);

    [processor segmentWithInput:inputBuffer.get() output:outputBuffer.get()];

    cv::Mat expectedMat = LTLoadMatFromBundle(bundle, @"tree_segmentation.png");
    LTCVPixelBufferImageForReading(outputBuffer.get(), ^(const cv::Mat &outputMat) {
      expect($(outputMat)).to.beCloseToMatNormalizedHamming($(expectedMat), 0.01);
    });
  });
});

DeviceSpecEnd
