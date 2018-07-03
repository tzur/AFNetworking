// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKPersonSegmentationProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

DeviceSpecBegin(PNKPersonSegmentationProcessor)

context(@"segment", ^{
  it(@"should segment RGBA image correctly", ^{
    NSBundle *bundle = NSBundle.lt_testBundle;
    NSError *error;
    auto networkModelURL = [NSURL URLWithString:[bundle lt_pathForResource:@"person.nnmodel"]];
    auto processor = [[PNKPersonSegmentationProcessor alloc] initWithNetworkModel:networkModelURL
                                                                            error:&error];

    cv::Mat4b inputMat = LTLoadMatFromBundle(bundle, @"person.png");

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

    cv::Mat expectedMat = LTLoadMatFromBundle(bundle, @"person_processor_mask.png");
    LTCVPixelBufferImageForReading(outputBuffer.get(), ^(const cv::Mat &outputMat) {
      expect($(outputMat)).to.beCloseToMatWithin($(expectedMat), 6);
    });
  });

  it(@"should segment grayscale image correctly", ^{
    NSBundle *bundle = NSBundle.lt_testBundle;
    NSError *error;
    auto networkModelURL = [NSURL URLWithString:[bundle lt_pathForResource:@"person.nnmodel"]];
    auto processor = [[PNKPersonSegmentationProcessor alloc] initWithNetworkModel:networkModelURL
                                                                            error:&error];

    cv::Mat4b rgbaMat = LTLoadMatFromBundle(bundle, @"person.png");

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

    cv::Mat expectedMat = LTLoadMatFromBundle(bundle, @"person_grayscale_processor_mask.png");
    LTCVPixelBufferImageForReading(outputBuffer.get(), ^(const cv::Mat &outputMat) {
      expect($(outputMat)).to.beCloseToMatWithin($(expectedMat), 8);
    });
  });
});

DeviceSpecEnd
