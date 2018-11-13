// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKHairSegmentationProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

DeviceSpecBegin(PNKHairSegmentationProcessor)

__block NSBundle *bundle;
__block PNKHairSegmentationProcessor *processor;

beforeEach(^{
  bundle = NSBundle.lt_testBundle;
  NSError *error;
  auto networkModelURL = [NSURL URLWithString:[bundle lt_pathForResource:@"hair.nnmodel"]];
  processor = [[PNKHairSegmentationProcessor alloc] initWithNetworkModel:networkModelURL
                                                                   error:&error];
});

afterEach(^{
  bundle = nil;
  processor = nil;
});

context(@"segment", ^{
  it(@"should segment RGBA image correctly", ^{
    cv::Mat4b inputMat = LTLoadMatFromBundle(bundle, @"hair_input.png");

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

    cv::Mat expectedMat = LTLoadMatFromBundle(bundle, @"hair_output.png");
    LTCVPixelBufferImageForReading(outputBuffer.get(), ^(const cv::Mat &outputMat) {
      expect($(outputMat)).to.beCloseToMatIntersectionOverUnion($(expectedMat), @0.01);
    });
  });
});

context(@"output size", ^{
  static const NSUInteger kImageWidth = 1024;
  static const NSUInteger kImageHeight = 1536;

  it(@"should calculate correct output size", ^{
    auto inputSize = CGSizeMake(kImageWidth, kImageHeight);
    auto expectedOutputSize = CGSizeMake(256, (kImageHeight * 256) / kImageWidth);
    auto outputSize = [processor outputSizeWithInputSize:inputSize];
    expect(@(outputSize)).to.equal(@(expectedOutputSize));
  });

  it(@"should raise when output pixel buffer has wrong size", ^{
    auto inputBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight, kCVPixelFormatType_32BGRA);
    auto outputSize = [processor outputSizeWithInputSize:CGSizeMake(kImageWidth, kImageHeight)];
    auto outputBuffer = LTCVPixelBufferCreate(outputSize.width, outputSize.height + 1,
                                              kCVPixelFormatType_OneComponent8);

    expect(^{
      [processor segmentWithInput:inputBuffer.get() output:outputBuffer.get() completion:^{}];
    }).to.raise(NSInvalidArgumentException);
  });
});

DeviceSpecEnd
