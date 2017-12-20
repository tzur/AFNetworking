// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKSkySegmentationProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

DeviceSpecBegin(PNKSkySegmentationProcessor)

context(@"segment", ^{
  it(@"should segment image correctly", ^{
    NSBundle *bundle = [NSBundle bundleForClass:[PNKSkySegmentationProcessorSpec class]];
    NSError *error;
    auto networkModelURL =
        [NSURL URLWithString:[bundle lt_pathForResource:@"PNKSkySegmentation.nnmodel"]];
    auto shapeModelURL =
        [NSURL URLWithString:[bundle lt_pathForResource:@"PNKSkyShape512.model"]];
    auto processor = [[PNKSkySegmentationProcessor alloc] initWithNetworkModel:networkModelURL
                                                                    shapeModel:shapeModelURL
                                                                         error:&error];

    cv::Mat4b inputMat = LTLoadMat([self class], @"Bicycles1200.jpg");
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

    cv::Mat expectedMat = LTLoadMat([self class], @"Bicycles_skymask512.png");
    LTCVPixelBufferImageForReading(outputBuffer.get(), ^(const cv::Mat &outputMat) {
      expect($(outputMat)).to.beCloseToMatWithin($(expectedMat), 3);
    });

    auto upsampledOutputBuffer = LTCVPixelBufferCreate(inputMat.cols, inputMat.rows,
                                                       kCVPixelFormatType_OneComponent8);

    expect(^{
      [processor upsampleImage:outputBuffer.get() withGuide:inputBuffer.get()
                        output:upsampledOutputBuffer.get()];
    }).notTo.raiseAny();
  });
});

DeviceSpecEnd
