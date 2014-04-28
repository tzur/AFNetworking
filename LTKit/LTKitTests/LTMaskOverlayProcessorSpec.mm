// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMaskOverlayProcessor.h"

#import "LTTexture+Factory.h"

SpecBegin(LTMaskOverlayProcessorSpec)

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

context(@"processing", ^{
  __block LTMaskOverlayProcessor *processor;
  __block LTTexture *input;

  beforeEach(^{
    cv::Mat4b inputImage(16, 16, cv::Vec4b(128, 64, 32, 255));
    cv::Mat1b maskImage(inputImage.size(), 128);
    maskImage(cv::Rect(0, 0, 4, 4)) = 255;

    input = [LTTexture textureWithImage:inputImage];
    LTTexture *mask = [LTTexture textureWithImage:maskImage];
    LTTexture *output = [LTTexture textureWithPropertiesOf:input];

    processor = [[LTMaskOverlayProcessor alloc] initWithImage:input mask:mask output:output];
  });

  afterEach(^{
    input = nil;
    processor = nil;
  });

  it(@"should add default mask correctly", ^{
    LTSingleTextureOutput *result = [processor process];

    cv::Mat4b expected(input.size.height, input.size.width, cv::Vec4b(160, 48, 24, 255));
    expected(cv::Rect(0, 0, 4, 4)) = cv::Vec4b(192, 32, 16, 255);

    expect($([result.texture image])).to.beCloseToMat($(expected));
  });

  it(@"should add custom mask color correctly", ^{
    processor.maskColor = GLKVector4Make(0.5, 0.25, 0.75, 1.0);
    LTSingleTextureOutput *result = [processor process];

    cv::Mat4b expected(input.size.height, input.size.width, cv::Vec4b(128, 64, 112, 255));
    expected(cv::Rect(0, 0, 4, 4)) = cv::Vec4b(128, 64, 192, 255);

    expect($([result.texture image])).to.beCloseToMat($(expected));
  });
});

SpecEnd
