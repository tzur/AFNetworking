// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKSingleStyleTransferProcessor.h"

#import <LTEngine/LTCVPixelBufferExtensions.h>

SpecBegin(PNKSingleStyleTransferProcessor)

/// Red color in 4 channels Uchar.
const static cv::Vec4b kRedColor(255, 0, 0, 255);

/// Blue color in 4 channels Uchar.
const static cv::Vec4b kBlueColor(0, 0, 255, 255);

/// Input image size
const static cv::Size kInputSize(512, 512);

context(@"testing stub stylizing", ^{
  __block PNKSingleStyleTransferProcessor *processor;
  __block lt::Ref<CVPixelBufferRef> inputBuffer;

  beforeEach(^{
    NSError *error;
    processor = [[PNKSingleStyleTransferProcessor alloc]
                 initWithModel:[NSURL fileURLWithPath:@"blah"] error:&error];
    inputBuffer = LTCVPixelBufferCreate(kInputSize.width, kInputSize.height,
                                        kCVPixelFormatType_32BGRA);
    LTCVPixelBufferImageForWriting(inputBuffer.get(), ^(cv::Mat *inputMat) {
      inputMat->setTo(kRedColor);
    });
  });

  it(@"should resize and change color as stylization stub", ^{
    auto outputBuffer = [processor stylizeWithInput:inputBuffer.get()];

    cv::Mat4b expected(processor.stylizedOutputSize.width, processor.stylizedOutputSize.height,
                       kBlueColor);

    LTCVPixelBufferImageForReading(outputBuffer.get(), ^(const cv::Mat &result) {
      expect($(result)).to.equalMat($(expected));
    });
  });
});

SpecEnd
