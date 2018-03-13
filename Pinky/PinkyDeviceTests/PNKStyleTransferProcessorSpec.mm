// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKStyleTransferProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

DeviceSpecBegin(PNKStyleTransferProcessor)

__block PNKStyleTransferProcessor *processor;

static NSString * const kGreyNetworkFileName = @"sketch.nnmodel";

static NSString * const kLargeImageFileName = @"Lena.png";

context(@"stylize", ^{
  it(@"should stylize image correctly using a greyscale input network", ^{
    NSBundle *bundle = NSBundle.lt_testBundle;
    NSError *error;
    auto modelURL = [NSURL URLWithString:[bundle lt_pathForResource:kGreyNetworkFileName]];
    processor = [[PNKStyleTransferProcessor alloc] initWithModel:modelURL error:&error];

    cv::Mat4b inputMat = LTLoadMat([self class], kLargeImageFileName);
    auto inputBuffer = LTCVPixelBufferCreate(inputMat.cols, inputMat.rows,
                                             kCVPixelFormatType_32BGRA);
    LTCVPixelBufferImageForWriting(inputBuffer.get(), ^(cv::Mat * _Nonnull image) {
      inputMat.copyTo(*image);
    });

    auto outputSize = [processor outputSizeWithInputSize:CGSizeMake(inputMat.cols, inputMat.rows)];
    auto outputBuffer = LTCVPixelBufferCreate(outputSize.width, outputSize.height,
                                              kCVPixelFormatType_OneComponent8);

    waitUntil(^(DoneCallback done) {
      [processor stylizeWithInput:inputBuffer.get() output:outputBuffer.get() styleIndex:1
                       completion:^(PNKStyleTransferState * __unused state){
         done();
      }];
    });

    cv::Mat1b expectedMat = LTLoadMat([self class], @"Lena_sketch1.png");
    LTCVPixelBufferImageForReading(outputBuffer.get(), ^(const cv::Mat &outputMat) {
      expect($(outputMat)).to.beCloseToMatPSNR($(expectedMat), 39);
    });
  });

  it(@"should stylize image correctly using a cached state", ^{
    NSBundle *bundle = NSBundle.lt_testBundle;
    NSError *error;
    auto modelURL = [NSURL URLWithString:[bundle lt_pathForResource:kGreyNetworkFileName]];
    processor = [[PNKStyleTransferProcessor alloc] initWithModel:modelURL error:&error];

    cv::Mat4b inputMat = LTLoadMat([self class], kLargeImageFileName);
    auto inputBuffer = LTCVPixelBufferCreate(inputMat.cols, inputMat.rows,
                                             kCVPixelFormatType_32BGRA);
    LTCVPixelBufferImageForWriting(inputBuffer.get(), ^(cv::Mat * _Nonnull image) {
      inputMat.copyTo(*image);
    });

    auto outputSize = [processor outputSizeWithInputSize:CGSizeMake(inputMat.cols, inputMat.rows)];
    auto outputBuffer1 = LTCVPixelBufferCreate(outputSize.width, outputSize.height,
                                               kCVPixelFormatType_OneComponent8);

    __block PNKStyleTransferState *state;

    waitUntil(^(DoneCallback done) {
      [processor stylizeWithInput:inputBuffer.get() output:outputBuffer1.get() styleIndex:1
                       completion:^(PNKStyleTransferState *returnedState){
         state = returnedState;
         done();
      }];
    });

    auto outputBuffer2 = LTCVPixelBufferCreate(outputSize.width, outputSize.height,
                                               kCVPixelFormatType_OneComponent8);
    waitUntil(^(DoneCallback done) {
      [processor stylizeWithState:state output:outputBuffer2.get() styleIndex:1
                       completion:^{
         done();
      }];
    });

    LTCVPixelBufferImageForReading(outputBuffer1.get(), ^(const cv::Mat &outputMat1) {
      LTCVPixelBufferImageForReading(outputBuffer2.get(), ^(const cv::Mat &outputMat2) {
        expect($(outputMat1)).to.equalMat($(outputMat2));
      });
    });
  });
});

SpecEnd
