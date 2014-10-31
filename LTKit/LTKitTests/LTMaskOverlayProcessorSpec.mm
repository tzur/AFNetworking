// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMaskOverlayProcessor.h"

#import "LTFbo.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTMaskOverlayProcessorSpec)

context(@"processing", ^{
  __block LTMaskOverlayProcessor *processor;
  __block LTTexture *input;
  __block LTTexture *mask;
  __block LTTexture *output;

  beforeEach(^{
    cv::Mat4b inputImage(16, 16, cv::Vec4b(128, 64, 32, 255));
    cv::Mat1b maskImage(inputImage.size(), 128);
    maskImage(cv::Rect(0, 0, 4, 4)).setTo(0);

    input = [LTTexture textureWithImage:inputImage];
    mask = [LTTexture textureWithImage:maskImage];
    output = [LTTexture textureWithPropertiesOf:input];

    processor = [[LTMaskOverlayProcessor alloc] initWithImage:input mask:mask output:output];
  });

  afterEach(^{
    output = nil;
    input = nil;
    mask = nil;
    processor = nil;
  });

  it(@"should add default mask correctly", ^{
    [processor process];

    cv::Mat4b expected(input.size.height, input.size.width, cv::Vec4b(160, 48, 24, 255));
    expected(cv::Rect(0, 0, 4, 4)) = cv::Vec4b(192, 32, 16, 255);

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should add custom mask color correctly", ^{
    processor.maskColor = LTVector4(0.5, 0.25, 0.75, 1.0);
    [processor process];

    cv::Mat4b expected(input.size.height, input.size.width, cv::Vec4b(128, 64, 112, 255));
    expected(cv::Rect(0, 0, 4, 4)) = cv::Vec4b(128, 64, 192, 255);

    expect($([output image])).to.beCloseToMat($(expected));
  });
  
  it(@"should use framebuffer as input in case the input and output are equal", ^{
    processor = [[LTMaskOverlayProcessor alloc] initWithImage:input mask:mask output:input];
    [input cloneTo:output];
    [input clearWithColor:LTVector4Zero];
    LTFbo *fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo bindAndDraw:^{
      [processor processToFramebufferWithSize:fbo.size outputRect:CGRectFromSize(fbo.size)];
    }];
    
    cv::Mat4b expected(input.size.height, input.size.width, cv::Vec4b(160, 48, 24, 255));
    expected(cv::Rect(0, 0, 4, 4)) = cv::Vec4b(192, 32, 16, 255);
    
    expect($([output image])).to.beCloseToMat($(expected));
  });
});

LTSpecEnd
