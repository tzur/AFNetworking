// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKInpaintingProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

DeviceSpecBegin(PNKInpaintingProcessor)
  __block BOOL isSupported;

context(@"inpainting processor", ^{
  beforeEach(^{
    isSupported = [MTLCreateSystemDefaultDevice()
                   supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily3_v1];
  });

  context(@"parameters validation", ^{
    static const int kImageWidth = 512;
    static const int kImageHeight = 512;

    __block PNKInpaintingProcessor *processor;

    beforeEach(^{
      NSBundle *bundle = NSBundle.lt_testBundle;
      auto networkModelURL = [NSURL
                              URLWithString:[bundle lt_pathForResource:@"inpainting.nnmodel"]];
      processor = [[PNKInpaintingProcessor alloc] initWithNetworkModel:networkModelURL error:nil];
    });

    afterEach(^{
      processor = nil;
    });

    it(@"should raise when input width differs from mask width", ^{
      if (!isSupported) {
        return;
      }

      auto inputBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight,
                                               kCVPixelFormatType_32BGRA);
      auto maskBuffer = LTCVPixelBufferCreate(kImageWidth + 1, kImageHeight,
                                              kCVPixelFormatType_OneComponent8);
      auto outputBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight,
                                                kCVPixelFormatType_32BGRA);

      expect(^{
        [processor inpaintWithInput:inputBuffer.get() mask:maskBuffer.get()
                             output:outputBuffer.get() completion:^{}];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input height differs from mask height", ^{
      if (!isSupported) {
        return;
      }

      auto inputBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight,
                                               kCVPixelFormatType_32BGRA);
      auto maskBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight + 1,
                                              kCVPixelFormatType_OneComponent8);
      auto outputBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight,
                                                kCVPixelFormatType_32BGRA);

      expect(^{
        [processor inpaintWithInput:inputBuffer.get() mask:maskBuffer.get()
                             output:outputBuffer.get() completion:^{}];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input width differs from output width", ^{
      if (!isSupported) {
        return;
      }

      auto inputBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight,
                                               kCVPixelFormatType_32BGRA);
      auto maskBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight,
                                              kCVPixelFormatType_OneComponent8);
      auto outputBuffer = LTCVPixelBufferCreate(kImageWidth + 1, kImageHeight,
                                                kCVPixelFormatType_32BGRA);

      expect(^{
        [processor inpaintWithInput:inputBuffer.get() mask:maskBuffer.get()
                             output:outputBuffer.get() completion:^{}];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input height differs from output height", ^{
      if (!isSupported) {
        return;
      }

      auto inputBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight,
                                               kCVPixelFormatType_32BGRA);
      auto maskBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight,
                                              kCVPixelFormatType_OneComponent8);
      auto outputBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight + 1,
                                                kCVPixelFormatType_32BGRA);

      expect(^{
        [processor inpaintWithInput:inputBuffer.get() mask:maskBuffer.get()
                             output:outputBuffer.get() completion:^{}];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when input pixel format differs from output pixel format", ^{
      if (!isSupported) {
        return;
      }

      auto inputBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight,
                                               kCVPixelFormatType_32BGRA);
      auto maskBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight,
                                              kCVPixelFormatType_OneComponent8);
      auto outputBuffer = LTCVPixelBufferCreate(kImageWidth, kImageHeight,
                                                kCVPixelFormatType_64ARGB);

      expect(^{
        [processor inpaintWithInput:inputBuffer.get() mask:maskBuffer.get()
                             output:outputBuffer.get() completion:^{}];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"inpaint", ^{
    it(@"should inpaint image correctly", ^{
      if (!isSupported) {
        return;
      }

      NSBundle *bundle = NSBundle.lt_testBundle;

      NSError *error;
      auto networkModelURL = [NSURL
                              URLWithString:[bundle lt_pathForResource:@"inpainting.nnmodel"]];
      auto processor = [[PNKInpaintingProcessor alloc] initWithNetworkModel:networkModelURL
                                                                      error:&error];

      cv::Mat4b inputMat = LTLoadMatFromBundle(bundle, @"fieldInput.jpg");
      cv::Mat1b maskMat = LTLoadMatFromBundle(bundle, @"fieldMask.png");

      auto inputBuffer = LTCVPixelBufferCreate(inputMat.cols, inputMat.rows,
                                               kCVPixelFormatType_32BGRA);
      LTCVPixelBufferImageForWriting(inputBuffer.get(), ^(cv::Mat *image) {
        inputMat.copyTo(*image);
      });

      auto maskBuffer = LTCVPixelBufferCreate(inputMat.cols, inputMat.rows,
                                               kCVPixelFormatType_OneComponent8);
      LTCVPixelBufferImageForWriting(maskBuffer.get(), ^(cv::Mat *image) {
        maskMat.copyTo(*image);
      });

      auto outputBuffer = LTCVPixelBufferCreate(inputMat.cols, inputMat.rows,
                                                kCVPixelFormatType_32BGRA);

      waitUntil(^(DoneCallback done) {
        [processor inpaintWithInput:inputBuffer.get() mask:maskBuffer.get()
                             output:outputBuffer.get() completion:^{
          done();
        }];
      });

      cv::Mat expectedMat = LTLoadMatFromBundle(bundle, @"fieldOutput.png");
      LTCVPixelBufferImageForReading(outputBuffer.get(), ^(const cv::Mat &outputMat) {
        expect($(outputMat)).to.beCloseToMatPSNR($(expectedMat), 46);
      });
    });
  });
});

DeviceSpecEnd
