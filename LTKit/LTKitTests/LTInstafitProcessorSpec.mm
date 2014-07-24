// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTInstafitProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecGLBegin(LTInstafitProcessor)

context(@"initialization", ^{
  it(@"should not intitialize if output texture is not a square", ^{
    LTTexture *input = [LTTexture textureWithImage:cv::Mat4b(4, 4)];
    LTTexture *mask = [LTTexture textureWithSize:input.size precision:LTTexturePrecisionByte
                                          format:LTTextureFormatRed allocateMemory:YES];
    LTTexture *output = [LTTexture byteRGBATextureWithSize:CGSizeMake(3, 4)];

    expect(^{
      LTInstafitProcessor __unused *processor = [[LTInstafitProcessor alloc] initWithInput:input
                                                                                      mask:mask
                                                                                    output:output];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"properties", ^{
  it(@"should set white background when setting it to nil", ^{
    LTTexture *input = [LTTexture textureWithImage:cv::Mat4b(4, 4)];
    LTTexture *mask = [LTTexture textureWithSize:input.size precision:LTTexturePrecisionByte
                                          format:LTTextureFormatRed allocateMemory:YES];
    LTTexture *output = [LTTexture byteRGBATextureWithSize:input.size];

    LTInstafitProcessor *processor = [[LTInstafitProcessor alloc] initWithInput:input
                                                                           mask:mask
                                                                         output:output];
    [processor process];
  });
});

context(@"processing", ^{
  __block cv::Mat4b inputImage;
  __block LTTexture *input;
  __block LTTexture *mask;
  __block LTTexture *output;
  __block LTInstafitProcessor *processor;

  beforeEach(^{
    inputImage = LTLoadMat([self class], @"Lena128.png");
    input = [LTTexture textureWithImage:inputImage];
    mask = [LTTexture textureWithSize:input.size precision:LTTexturePrecisionByte
                               format:LTTextureFormatRed allocateMemory:YES];
    output = [LTTexture byteRGBATextureWithSize:CGSizeMake(256, 256)];

    [mask clearWithColor:GLKVector4Make(1, 1, 1, 1)];

    processor = [[LTInstafitProcessor alloc] initWithInput:input mask:mask output:output];
  });

  afterEach(^{
    input = nil;
    output = nil;
    mask = nil;
    processor = nil;
  });

  it(@"should place image with default background", ^{
    [processor process];

    cv::Mat4b expected(output.size.height, output.size.width, cv::Vec4b(255, 255, 255, 255));
    inputImage.copyTo(expected(cv::Rect(0, 0, inputImage.cols, inputImage.rows)));

    expect($([output image])).to.equalMat($(expected));
  });

  it(@"should place image with custom single color background", ^{
    processor.background = [LTTexture textureWithImage:cv::Mat4b(1, 1, cv::Vec4b(255, 0, 0, 255))];
    [processor process];

    cv::Mat4b expected(output.size.height, output.size.width, cv::Vec4b(255, 0, 0, 255));
    inputImage.copyTo(expected(cv::Rect(0, 0, inputImage.cols, inputImage.rows)));

    expect($([output image])).to.equalMat($(expected));
  });

  it(@"should place image with custom tiled texture", ^{
    cv::Mat4b texture(16, 16, cv::Vec4b(255, 0, 0, 255));
    texture(cv::Rect(0, 0, 8, 8)).setTo(cv::Vec4b(0, 255, 0, 255));
    texture(cv::Rect(8, 8, 8, 8)).setTo(cv::Vec4b(0, 0, 255, 255));

    processor.background = [LTTexture textureWithImage:texture];
    [processor process];

    cv::Mat4b expected(output.size.height, output.size.width);
    for (int y = 0; y < expected.cols; y += texture.cols) {
      for (int x = 0; x < expected.cols; x += texture.cols) {
        texture.copyTo(expected(cv::Rect(x, y, texture.cols, texture.rows)));
      }
    }
    inputImage.copyTo(expected(cv::Rect(0, 0, inputImage.cols, inputImage.rows)));

    expect($([output image])).to.equalMat($(expected));
  });

  it(@"should place image with correct mask", ^{
    cv::Mat1b maskImage(mask.size.height, mask.size.width, 255);
    maskImage(cv::Rect(0, 0, mask.size.width / 2, mask.size.height)) = 128;

    [mask load:maskImage];

    [processor process];

    cv::Mat4b expected(output.size.height, output.size.width, cv::Vec4b(255, 255, 255, 255));
    inputImage.copyTo(expected(cv::Rect(0, 0, inputImage.cols, inputImage.rows)));

    cv::Rect rightROI(0, 0, inputImage.cols / 2, inputImage.rows);
    cv::Mat4b whiteImage(rightROI.height, rightROI.width, cv::Vec4b(255, 255, 255, 255));
    cv::addWeighted(inputImage(rightROI), 0.5, whiteImage, 0.5, 0, expected(rightROI));

    expect($([output image])).to.beCloseToMat($(expected));
  });

  it(@"should translate input image", ^{
    processor.translation = CGPointMake(5, 5);
    [processor process];

    cv::Mat4b expected(output.size.height, output.size.width, cv::Vec4b(255, 255, 255, 255));
    inputImage.copyTo(expected(cv::Rect(processor.translation.x, processor.translation.y,
                                        inputImage.cols, inputImage.rows)));

    expect($([output image])).to.equalMat($(expected));
  });

  it(@"should scale input image", ^{
    input.magFilterInterpolation = LTTextureInterpolationNearest;
    processor.translation = CGPointMake(inputImage.cols / 2, inputImage.rows / 2);
    processor.scaling = 2.0;
    [processor process];

    cv::Mat4b expected(output.size.height, output.size.width);
    cv::resize(inputImage, expected, expected.size(), 0, 0, cv::INTER_NEAREST);

    expect($([output image])).to.equalMat($(expected));
  });

  it(@"should rotate input image", ^{
    input.magFilterInterpolation = LTTextureInterpolationNearest;
    processor.rotation = M_PI_2;
    [processor process];

    cv::Mat4b expected(output.size.height, output.size.width, cv::Vec4b(255, 255, 255, 255));
    cv::Rect roi(0, 0, inputImage.cols, inputImage.rows);
    cv::flip(inputImage, expected(roi), 0);
    cv::transpose(expected(roi), expected(roi));

    expect($([output image])).to.equalMat($(expected));
  });
});

SpecGLEnd
