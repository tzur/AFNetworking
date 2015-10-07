// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuadCopyProcessor.h"

#import "LTFbo.h"
#import "LTQuad.h"
#import "LTRotatedRect.h"
#import "LTTexture+Factory.h"

SpecBegin(LTQuadCopyProcessor)

__block cv::Mat4b image;
__block LTTexture *input;
__block LTTexture *output;
__block LTQuadCopyProcessor *processor;

beforeEach(^{
  image.create(16, 16);
  image(cv::Rect(0, 0, 8, 8)) = cv::Vec4b(255, 0, 0, 255);
  image(cv::Rect(8, 0, 8, 8)) = cv::Vec4b(0, 255, 0, 255);
  image(cv::Rect(0, 8, 8, 8)) = cv::Vec4b(0, 0, 255, 255);
  image(cv::Rect(8, 8, 8, 8)) = cv::Vec4b(255, 255, 0, 255);

  input = [LTTexture textureWithImage:image];
  input.magFilterInterpolation = LTTextureInterpolationNearest;

  output = [LTTexture textureWithImage:cv::Mat4b::zeros(32, 32)];
  processor = [[LTQuadCopyProcessor alloc] initWithInput:input output:output];
});

afterEach(^{
  input = nil;
  output = nil;
  processor = nil;
});

context(@"initialization", ^{
  it(@"should have default values after initialization", ^{
    LTQuad *expectedInputQuad = [LTQuad quadFromRect:CGRectFromSize(input.size)];
    LTQuad *expectedOutputQuad = [LTQuad quadFromRect:CGRectFromSize(output.size)];

    expect(processor.inputQuad).to.equal(expectedInputQuad);
    expect(processor.outputQuad).to.equal(expectedOutputQuad);
  });
});

context(@"processing", ^{
  context(@"copying", ^{
    it(@"should copy non-rotated rect to non-rotated rect", ^{
      processor.inputQuad = [LTQuad quadFromRect:CGRectMake(0, 0, 8, 8)];
      processor.outputQuad = [LTQuad quadFromRect:CGRectMake(0, 0, 16, 16)];
      [processor process];

      cv::Mat4b expected(cv::Mat4b::zeros(32, 32));
      expected(cv::Rect(0, 0, 16, 16)) = cv::Vec4b(255, 0, 0, 255);

      expect($([output image])).to.equalMat($(expected));
    });

    it(@"should copy rotated rect to non-rotated rect", ^{
      processor.inputQuad =
          [LTQuad quadFromRotatedRect:[LTRotatedRect rect:CGRectMake(0, 0, 16, 16) withAngle:M_PI]];
      processor.outputQuad =
          [LTQuad quadFromRotatedRect:[LTRotatedRect rect:CGRectMake(0, 0, 16, 16)]];
      [processor process];

      cv::Mat4b flippedInput(image);
      cv::flip(flippedInput, flippedInput, 0);
      cv::flip(flippedInput, flippedInput, 1);
      cv::Mat4b expected(cv::Mat4b::zeros(32, 32));
      flippedInput.copyTo(expected(cv::Rect(0, 0, 16, 16)));

      expect($([output image])).to.equalMat($(expected));
    });

    it(@"should copy rect to quad", ^{
      processor.inputQuad = [LTQuad quadFromRect:CGRectMake(0, 0, 8, 8)];

      LTQuadCorners corners{{CGPointMake(0, 0), CGPointMake(32, 0), CGPointMake(1, 32),
          CGPointMake(0, 32)}};
      processor.outputQuad = [[LTQuad alloc] initWithCorners:corners];
      [processor process];

      cv::Mat4b expected(cv::Mat4b::zeros(32, 32));
      for (NSUInteger i = 0; i < 32; i++) {
        expected(cv::Rect(0, 0, (int)(32 - i), (int)(i + 1))) = cv::Vec4b(255, 0, 0, 255);
      }

      expect($([output image])).to.equalMat($(expected));
    });
  });

  context(@"screen processing", ^{
    __block LTTexture *framebufferTexture;
    __block LTFbo *fbo;
    __block CGRect outputRect;

    beforeEach(^{
      framebufferTexture = [LTTexture byteRGBATextureWithSize:output.size / 2];
      [framebufferTexture clearWithColor:LTVector4Zero];
      fbo = [[LTFbo alloc] initWithTexture:framebufferTexture];
      outputRect = CGRectCenteredAt(CGPointFromSize(output.size / 2 + CGSizeMakeUniform(1)),
                                    output.size / 4);
    });

    afterEach(^{
      framebufferTexture = nil;
      fbo = nil;
    });

    it(@"should copy non-rotated rect to non-rotated rect", ^{
      processor.inputQuad = [LTQuad quadFromRect:CGRectMake(0, 0, 8, 8)];
      processor.outputQuad = [LTQuad quadFromRect:CGRectMake(0, 0, 16, 16)];

      [fbo bindAndDraw:^{
        [processor processToFramebufferWithSize:fbo.size outputRect:outputRect];
      }];

      cv::Mat4b expected(cv::Mat4b::zeros(16, 16));
      expected(cv::Rect(0, 0, 6, 6)) = cv::Vec4b(255, 0, 0, 255);

      expect($([framebufferTexture image])).to.equalMat($(expected));
    });

    it(@"should copy rotated rect to non-rotated rect", ^{
      processor.inputQuad =
          [LTQuad quadFromRotatedRect:[LTRotatedRect rect:CGRectMake(0, 0, 16, 16) withAngle:M_PI]];
      processor.outputQuad =
          [LTQuad quadFromRotatedRect:[LTRotatedRect rect:CGRectMake(0, 0, 16, 16)]];

      [fbo bindAndDraw:^{
        [processor processToFramebufferWithSize:fbo.size outputRect:outputRect];
      }];

      cv::Mat4b expected(cv::Mat4b::zeros(16, 16));
      expected(cv::Rect(0, 0, 6, 6)) = cv::Vec4b(255, 0, 0, 255);

      expect($([framebufferTexture image])).to.equalMat($(expected));
    });

    it(@"should copy rect to quad", ^{
      processor.inputQuad = [LTQuad quadFromRect:CGRectMake(0, 0, 8, 8)];

      LTQuadCorners corners{{CGPointMake(0, 0), CGPointMake(32, -1), CGPointMake(32, 0),
        CGPointMake(0, 32)}};
      processor.outputQuad = [[LTQuad alloc] initWithCorners:corners];

      [fbo bindAndDraw:^{
        [processor processToFramebufferWithSize:fbo.size outputRect:outputRect];
      }];

      cv::Mat4b expected(cv::Mat4b::zeros(16, 16));
      for (NSUInteger i = 0; i < 11; i++) {
        expected(cv::Rect(0, 0, (int)(11 - i), (int)(i + 1))) = cv::Vec4b(255, 0, 0, 255);
      }

      expect($([framebufferTexture image])).to.equalMat($(expected));
    });
  });
});

SpecEnd
