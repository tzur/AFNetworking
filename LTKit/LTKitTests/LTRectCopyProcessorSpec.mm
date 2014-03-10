// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectCopyProcessor.h"

#import "LTRotatedRect.h"
#import "LTTexture+Factory.h"

SpecBegin(LTRectCopyProcessor)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

__block cv::Mat4b image;
__block LTTexture *input;
__block LTTexture *output;
__block LTRectCopyProcessor *processor;

beforeEach(^{
  image.create(16, 16);
  image(cv::Rect(0, 0, 8, 8)) = cv::Vec4b(255, 0, 0, 255);
  image(cv::Rect(8, 0, 8, 8)) = cv::Vec4b(0, 255, 0, 255);
  image(cv::Rect(0, 8, 8, 8)) = cv::Vec4b(0, 0, 255, 255);
  image(cv::Rect(8, 8, 8, 8)) = cv::Vec4b(255, 255, 0, 255);

  input = [LTTexture textureWithImage:image];
  input.magFilterInterpolation = LTTextureInterpolationNearest;

  output = [LTTexture textureWithImage:cv::Mat4b::zeros(32, 32)];
  processor = [[LTRectCopyProcessor alloc] initWithInput:input output:output];
});

afterEach(^{
  input = nil;
  output = nil;
  processor = nil;
});

context(@"initialization", ^{
  it(@"should have default values after initialization", ^{
    LTRotatedRect *expectedInputRect = [LTRotatedRect rect:CGRectMake(0, 0, input.size.width,
                                                                      input.size.height)];
    LTRotatedRect *expectedOutputRect = [LTRotatedRect rect:CGRectMake(0, 0, output.size.width,
                                                                       output.size.height)];

    expect(processor.inputRect).to.equal(expectedInputRect);
    expect(processor.outputRect).to.equal(expectedOutputRect);
  });
});

context(@"processing", ^{
  it(@"should copy non-rotated rect to non-rotated rect", ^{
    processor.inputRect = [LTRotatedRect rect:CGRectMake(0, 0, 8, 8)];
    processor.outputRect = [LTRotatedRect rect:CGRectMake(0, 0, 16, 16)];
    LTSingleTextureOutput *result = [processor process];

    cv::Mat4b expected(cv::Mat4b::zeros(32, 32));
    expected(cv::Rect(0, 0, 16, 16)) = cv::Vec4b(255, 0, 0, 255);

    expect($([result.texture image])).to.equalMat($(expected));
  });

  it(@"should copy rotated rect to non-rotated rect", ^{
    processor.inputRect = [LTRotatedRect rect:CGRectMake(0, 0, 16, 16) withAngle:M_PI];
    processor.outputRect = [LTRotatedRect rect:CGRectMake(0, 0, 16, 16)];
    LTSingleTextureOutput *result = [processor process];

    cv::Mat4b flippedInput(image);
    cv::flip(flippedInput, flippedInput, 0);
    cv::flip(flippedInput, flippedInput, 1);
    cv::Mat4b expected(cv::Mat4b::zeros(32, 32));
    flippedInput.copyTo(expected(cv::Rect(0, 0, 16, 16)));

    expect($([result.texture image])).to.equalMat($(expected));
  });
});

SpecEnd
