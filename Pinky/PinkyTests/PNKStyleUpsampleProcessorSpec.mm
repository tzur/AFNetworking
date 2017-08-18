// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKStyleUpsampleProcessor.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>

SpecBegin(PNKStyleUpsampleProcessor)

/// Red color in 4 channels Uchar.
const static cv::Vec4b kRedColor(255, 0, 0, 255);

/// Blue color in 4 channels Uchar.
const static cv::Vec4b kBlueColor(0, 0, 255, 255);

/// Input image size
const static cv::Size kInputSize(512, 512);

/// Stylized image size
const static cv::Size kStylizedSize(256, 256);

context(@"testing stub style upsampling", ^{
  __block PNKStyleUpsampleProcessor *processor;
  __block lt::Ref<CVPixelBufferRef> inputBuffer;

  beforeEach(^{
    NSError *error;
    processor = [[PNKStyleUpsampleProcessor alloc] initWithModel:[NSURL fileURLWithPath:@"blah"]
                                                           error:&error];
    inputBuffer = LTCVPixelBufferCreate(kInputSize.width, kInputSize.height,
                                        kCVPixelFormatType_32BGRA);
    LTCVPixelBufferImageForWriting(inputBuffer.get(), ^(cv::Mat *inputMat) {
      inputMat->setTo(kRedColor);
    });
  });

  it(@"should upsample to guide size as stub", ^{
    auto stylizedBuffer = LTCVPixelBufferCreate(kStylizedSize.width, kStylizedSize.height,
                                                kCVPixelFormatType_32BGRA);
    LTCVPixelBufferImageForWriting(stylizedBuffer.get(), ^(cv::Mat *stylizedMat) {
      stylizedMat->setTo(kBlueColor);
    });

    auto upsampledBuffer = LTCVPixelBufferCreate(kInputSize.width, kInputSize.height,
                                                 kCVPixelFormatType_32BGRA);
    [processor upsampleStylizedImage:stylizedBuffer.get() withGuide:inputBuffer.get()
                              output:upsampledBuffer.get()];

    cv::Mat4b expected(kInputSize, kBlueColor);

    LTCVPixelBufferImageForReading(upsampledBuffer.get(), ^(const cv::Mat &result) {
      expect($(result)).to.equalMat($(expected));
    });
  });
});

SpecEnd
