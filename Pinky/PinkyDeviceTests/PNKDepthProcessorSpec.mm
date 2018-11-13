// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKDepthProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

DeviceSpecBegin(PNKDepthProcessor)
__block BOOL isSupported;
__block NSBundle *bundle;
__block PNKDepthProcessor *processor;

beforeEach(^{
  isSupported = [MTLCreateSystemDefaultDevice() supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily3_v1];
  bundle = NSBundle.lt_testBundle;
  NSError *error;
  auto networkModelURL = [NSURL URLWithString:[bundle lt_pathForResource:@"depth.nnmodel"]];
  processor = [[PNKDepthProcessor alloc] initWithNetworkModel:networkModelURL error:&error];
});

afterEach(^{
  bundle = nil;
  processor = nil;
});

context(@"extract depth", ^{
  it(@"should extract depth correctly", ^{
    if (!isSupported) {
      return;
    }

    cv::Mat4b inputMat = LTLoadMatFromBundle(bundle, @"city.png");

    auto inputBuffer = LTCVPixelBufferCreate(inputMat.cols, inputMat.rows,
                                             kCVPixelFormatType_32BGRA);
    LTCVPixelBufferImageForWriting(inputBuffer.get(), ^(cv::Mat * _Nonnull image) {
      inputMat.copyTo(*image);
    });

    auto outputSize = [processor outputSizeWithInputSize:CGSizeMake(inputMat.cols, inputMat.rows)];
    auto outputBuffer = LTCVPixelBufferCreate(outputSize.width, outputSize.height,
                                              kCVPixelFormatType_OneComponent8);

    waitUntil(^(DoneCallback done) {
      [processor extractDepthWithInput:inputBuffer.get() output:outputBuffer.get() completion:^{
        done();
      }];
    });

    auto expectedMat = LTLoadMatFromBundle(bundle, @"city_depth.png");
    LTCVPixelBufferImageForReading(outputBuffer.get(), ^(const cv::Mat &outputMat) {
      expect($(outputMat)).to.beCloseToMatWithin($(expectedMat), 3);
    });
  });
});

context(@"output size", ^{
  static const NSUInteger kImageWidth = 1023;
  static const NSUInteger kImageHeight = 769;

  it(@"should calculate correct output size", ^{
    if (!isSupported) {
      return;
    }

    auto inputSize = CGSizeMake(kImageWidth, kImageHeight);
    auto expectedOutputSize = CGSizeMake(512, (kImageHeight * 512) / kImageWidth);
    auto outputSize = [processor outputSizeWithInputSize:inputSize];
    expect(@(outputSize)).to.equal(@(expectedOutputSize));
  });

  it(@"should raise when output pixel buffer has wrong size", ^{
    if (!isSupported) {
      return;
    }

    auto inputBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight, kCVPixelFormatType_32BGRA);
    auto outputSize = [processor outputSizeWithInputSize:CGSizeMake(kImageWidth, kImageHeight)];
    auto outputBuffer = LTCVPixelBufferCreate(outputSize.width, outputSize.height + 1,
                                              kCVPixelFormatType_OneComponent8);

    expect(^{
      [processor extractDepthWithInput:inputBuffer.get() output:outputBuffer.get() completion:^{}];
    }).to.raise(NSInvalidArgumentException);
  });
});

DeviceSpecEnd
