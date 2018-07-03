// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKSuperSkySegmentationProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

DeviceSpecBegin(PNKSuperSkySegmentationProcessor)

context(@"segment", ^{
  it(@"should segment image correctly", ^{
    NSBundle *bundle = NSBundle.lt_testBundle;

    NSError *error;
    auto networkModelURL = [NSURL URLWithString:[bundle lt_pathForResource:@"sky.nnmodel"]];
    auto processor = [[PNKSuperSkySegmentationProcessor alloc] initWithNetworkModel:networkModelURL
                                                                              error:&error];

    cv::Mat4b inputMat = LTLoadMatFromBundle(bundle, @"Bicycles1200.jpg");

    auto inputBuffer = LTCVPixelBufferCreate(inputMat.cols, inputMat.rows,
                                             kCVPixelFormatType_32BGRA);
    LTCVPixelBufferImageForWriting(inputBuffer.get(), ^(cv::Mat * _Nonnull image) {
      inputMat.copyTo(*image);
    });

    auto outputSize = [processor outputSizeWithInputSize:CGSizeMake(inputMat.cols, inputMat.rows)];
    auto outputBuffer = LTCVPixelBufferCreate(outputSize.width, outputSize.height,
                                              kCVPixelFormatType_OneComponent8);

    waitUntil(^(DoneCallback done) {
      [processor segmentWithInput:inputBuffer.get() output:outputBuffer.get() completion:^{
        done();
      }];
    });

    cv::Mat expectedMat = LTLoadMatFromBundle(bundle, @"supersky_bicycles.png");
    LTCVPixelBufferImageForReading(outputBuffer.get(), ^(const cv::Mat &outputMat) {
      expect($(outputMat)).to.beCloseToMatWithin($(expectedMat), 3);
    });
  });

  it(@"should segment grayscale image correctly", ^{
    NSBundle *bundle = NSBundle.lt_testBundle;

    NSError *error;
    auto networkModelURL = [NSURL URLWithString:[bundle lt_pathForResource:@"sky.nnmodel"]];
    auto processor = [[PNKSuperSkySegmentationProcessor alloc] initWithNetworkModel:networkModelURL
                                                                              error:&error];

    cv::Mat4b rgbaMat = LTLoadMatFromBundle(bundle, @"Bicycles1200.jpg");

    auto inputBuffer = LTCVPixelBufferCreate(rgbaMat.cols, rgbaMat.rows,
                                             kCVPixelFormatType_OneComponent8);
    LTCVPixelBufferImageForWriting(inputBuffer.get(), ^(cv::Mat * _Nonnull image) {
      cv::cvtColor(rgbaMat, *image, cv::COLOR_RGBA2GRAY);
    });

    auto outputSize = [processor outputSizeWithInputSize:CGSizeMake(rgbaMat.cols, rgbaMat.rows)];
    auto outputBuffer = LTCVPixelBufferCreate(outputSize.width, outputSize.height,
                                              kCVPixelFormatType_OneComponent8);

    waitUntil(^(DoneCallback done) {
      [processor segmentWithInput:inputBuffer.get() output:outputBuffer.get() completion:^{
        done();
      }];
    });

    cv::Mat expectedMat = LTLoadMatFromBundle(bundle, @"supersky_grayscale_bicycles.png");
    LTCVPixelBufferImageForReading(outputBuffer.get(), ^(const cv::Mat &outputMat) {
      expect($(outputMat)).to.beCloseToMatWithin($(expectedMat), 3);
    });
  });
});

DeviceSpecEnd
