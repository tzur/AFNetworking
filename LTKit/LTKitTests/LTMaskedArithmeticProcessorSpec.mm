// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMaskedArithmeticProcessor.h"

#import "LTTexture+Factory.h"

using half_float::half;

SpecBegin(LTMaskedArithmeticProcessor)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

context(@"initialization", ^{
  it(@"should raise when initializing with different sized operands", ^{
    cv::Mat4b image(16, 16);
    LTTexture *mask = [LTTexture textureWithImage:image];
    LTTexture *first = [LTTexture textureWithImage:image];
    LTTexture *second = [LTTexture textureWithImage:image(cv::Rect(0, 0, 10, 10))];
    LTTexture *output = [LTTexture textureWithPropertiesOf:mask];

    expect(^{
      __unused LTMaskedArithmeticProcessor *processor = [[LTMaskedArithmeticProcessor alloc]
                                                         initWithFirstOperand:first
                                                         secondOperand:second
                                                         mask:mask output:output];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when initializing with different sized operand and mask", ^{
    cv::Mat4b image(16, 16);
    LTTexture *mask = [LTTexture textureWithImage:image(cv::Rect(0, 0, 10, 10))];
    LTTexture *first = [LTTexture textureWithImage:image];
    LTTexture *second = [LTTexture textureWithImage:image];
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

  LTSingleTextureOutput *result = [processor process];

  cv::Mat4hf expected(maskImage.size());
  expected.setTo(cv::Vec4hf(half(0), half(0), half(0), half(1)));
  expected(roi).setTo(cv::Vec4hf(half(0), half(-0.25), half(0.43921), half(1)));

  expect(LTFuzzyCompareMat(expected, result.texture.image)).to.beTruthy();
});

SpecEnd
