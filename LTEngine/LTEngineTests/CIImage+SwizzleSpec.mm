// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "CIImage+Swizzle.h"

#import "CVPixelBuffer+LTEngine.h"

SpecBegin(CIImage_Swizzle)

context(@"swizzle", ^{
  __block CIContext *context;

  beforeEach(^{
    context = [CIContext contextWithOptions:@{
      kCIContextWorkingColorSpace: [NSNull null],
      kCIContextOutputColorSpace: [NSNull null]
    }];
  });

  afterEach(^{
    context = nil;
  });

  it(@"should swizzle the red and blue channels", ^{
    cv::Mat4b input(16, 16, cv::Vec4b(32, 64, 96, 128));
    cv::Mat4b output(input.rows, input.cols);

    auto inputBuffer = LTCVPixelBufferCreate(input.cols, input.rows, kCVPixelFormatType_32BGRA);
    LTCVPixelBufferImageForWriting(inputBuffer.get(), ^(cv::Mat *image) {
      input.copyTo(*image);
    });

    CIImage *inputImage = [CIImage imageWithCVPixelBuffer:inputBuffer.get() options:@{
      kCIImageColorSpace: [NSNull null]
    }];

    [context render:inputImage toBitmap:output.data rowBytes:output.step[0]
             bounds:CGRectMake(0, 0, output.cols, output.rows) format:kCIFormatBGRA8
         colorSpace:NULL];
    expect($(output)).to.equalMat($(input));

    cv::Mat4b expected;
    cv::cvtColor(input, expected, cv::COLOR_RGBA2BGRA);

    CIImage *swizzledImage = inputImage.lt_swizzledImage;

    [context render:swizzledImage toBitmap:output.data rowBytes:output.step[0]
             bounds:CGRectMake(0, 0, output.cols, output.rows) format:kCIFormatBGRA8
         colorSpace:NULL];

    expect($(output)).to.equalMat($(expected));
  });
});

SpecEnd
