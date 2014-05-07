// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRectCopyProcessor.h"

#import "LTRotatedRect.h"
#import "LTTexture+Factory.h"

SpecGLBegin(LTRectCopyProcessor)

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
  context(@"stretched texture mode", ^{
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

  context(@"tiled texture mode", ^{
    beforeEach(^{
      // Create 4 red/green squares in the rect (0, 0, 8, 8).
      image(cv::Rect(0, 4, 4, 4)) = cv::Vec4b(0, 255, 0, 255);
      image(cv::Rect(4, 0, 4, 4)) = cv::Vec4b(0, 255, 0, 255);
      [input load:image];

      processor.texturingMode = LTRectCopyTexturingModeTile;
    });

    it(@"should tile input rect from origin to target rect", ^{
      processor.inputRect = [LTRotatedRect rect:CGRectMake(0, 0, 8, 8)];
      processor.outputRect = [LTRotatedRect rect:CGRectMake(0, 0, 16, 16)];
      LTSingleTextureOutput *result = [processor process];

      // There should be 4 tiles of the red/green texture in the rect (0, 0, 16, 16).
      cv::Mat4b expected(cv::Mat4b::zeros(32, 32));
      image(cv::Rect(0, 0, 8, 8)).copyTo(expected(cv::Rect(0, 0, 8, 8)));
      image(cv::Rect(0, 0, 8, 8)).copyTo(expected(cv::Rect(8, 0, 8, 8)));
      image(cv::Rect(0, 0, 8, 8)).copyTo(expected(cv::Rect(0, 8, 8, 8)));
      image(cv::Rect(0, 0, 8, 8)).copyTo(expected(cv::Rect(8, 8, 8, 8)));

      expect($([result.texture image])).to.equalMat($(expected));
    });

    it(@"should tile input translated rect from inner origin to target rect", ^{
      processor.inputRect = [LTRotatedRect rect:CGRectMake(2, 2, 10, 8)];
      processor.outputRect = [LTRotatedRect rect:CGRectMake(2, 2, 20, 16)];
      LTSingleTextureOutput *result = [processor process];

      // There should be 4 tiles of the red/green texture in the rect (0, 0, 16, 16).
      cv::Mat4b expected(cv::Mat4b::zeros(32, 32));
      image(cv::Rect(2, 2, 10, 8)).copyTo(expected(cv::Rect(2, 2, 10, 8)));
      image(cv::Rect(2, 2, 10, 8)).copyTo(expected(cv::Rect(12, 2, 10, 8)));
      image(cv::Rect(2, 2, 10, 8)).copyTo(expected(cv::Rect(2, 10, 10, 8)));
      image(cv::Rect(2, 2, 10, 8)).copyTo(expected(cv::Rect(12, 10, 10, 8)));

      expect($([result.texture image])).to.equalMat($(expected));
    });

    it(@"should tile input translated and rotated rect from inner origin to target rect", ^{
      processor.inputRect = [LTRotatedRect rect:CGRectMake(2, 2, 6, 8) withAngle:-M_PI_2];
      processor.outputRect = [LTRotatedRect rect:CGRectMake(2, 2, 12, 16)];
      LTSingleTextureOutput *result = [processor process];

      // There should be 4 tiles of the rotated red/green texture in the rect (0, 0, 16, 16).
      cv::Mat4b expected(cv::Mat4b::zeros(32, 32));

      cv::Mat4b segment(image(cv::Rect(1, 3, 8, 6)));
      cv::flip(segment, segment, 0);
      cv::transpose(segment, segment);

      segment.copyTo(expected(cv::Rect(2, 2, 6, 8)));
      segment.copyTo(expected(cv::Rect(8, 2, 6, 8)));
      segment.copyTo(expected(cv::Rect(2, 10, 6, 8)));
      segment.copyTo(expected(cv::Rect(8, 10, 6, 8)));

      expect($([result.texture image])).to.equalMat($(expected));
    });
  });
});

SpecGLEnd
