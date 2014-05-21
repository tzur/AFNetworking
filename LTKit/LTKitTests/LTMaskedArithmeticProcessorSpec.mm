// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMaskedArithmeticProcessor.h"

#import "LTTexture+Factory.h"

using half_float::half;

SpecGLBegin(LTMaskedArithmeticProcessor)

context(@"initialization", ^{
  it(@"should raise when initializing with different sized operands", ^{
    cv::Mat4b imageA = cv::Mat4b::zeros(16, 16);
    cv::Mat4b imageB = cv::Mat4b::zeros(14, 14);
    LTTexture *mask = [LTTexture textureWithImage:imageA];
    LTTexture *first = [LTTexture textureWithImage:imageA];
    LTTexture *second = [LTTexture textureWithImage:imageB];
    LTTexture *output = [LTTexture textureWithPropertiesOf:mask];

    expect(^{
      __unused LTMaskedArithmeticProcessor *processor = [[LTMaskedArithmeticProcessor alloc]
                                                         initWithFirstOperand:first
                                                         secondOperand:second
                                                         mask:mask output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when initializing with different sized operand and mask", ^{
    cv::Mat4b imageA = cv::Mat4b::zeros(16, 16);
    cv::Mat4b imageB = cv::Mat4b::zeros(14, 14);
    LTTexture *mask = [LTTexture textureWithImage:imageB];
    LTTexture *first = [LTTexture textureWithImage:imageA];
    LTTexture *second = [LTTexture textureWithImage:imageA];
    LTTexture *output = [LTTexture textureWithPropertiesOf:mask];

    expect(^{
      __unused LTMaskedArithmeticProcessor *processor = [[LTMaskedArithmeticProcessor alloc]
                                                         initWithFirstOperand:first
                                                         secondOperand:second
                                                         mask:mask output:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

it(@"should produce correct result", ^{
  cv::Mat1b maskImage = cv::Mat1b::zeros(32, 32);
  cv::Rect roi(16, 16, 16, 16);
  maskImage(roi) = 255;

  cv::Mat4b firstImage(maskImage.size(), cv::Vec4b(128, 64, 128, 255));
  cv::Mat4b secondImage(maskImage.size(), cv::Vec4b(128, 128, 16, 255));

  LTTexture *mask = [LTTexture textureWithImage:maskImage];
  LTTexture *first = [LTTexture textureWithImage:firstImage];
  LTTexture *second = [LTTexture textureWithImage:secondImage];
  LTTexture *output = [LTTexture textureWithSize:mask.size
                                       precision:LTTexturePrecisionHalfFloat
                                          format:LTTextureFormatRGBA
                                  allocateMemory:YES];

  LTMaskedArithmeticProcessor *processor = [[LTMaskedArithmeticProcessor alloc]
                                            initWithFirstOperand:first secondOperand:second
                                            mask:mask output:output];

  [processor process];

  cv::Mat4hf expected(maskImage.size());
  expected.setTo(cv::Vec4hf(half(0), half(0), half(0), half(1)));
  expected(roi).setTo(cv::Vec4hf(half(0), half(-0.25), half(0.43921), half(1)));

  expect($(output.image)).to.beCloseToMat($(expected));
});

SpecGLEnd
