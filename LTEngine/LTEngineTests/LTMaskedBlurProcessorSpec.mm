// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kupchick.

#import "LTMaskedBlurProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"
#import "LTVector.h"

static const CGSize kMaskSize = CGSizeMakeUniform(2);

SpecBegin(LTMaskedBlurProcessor)

context(@"tests", ^{
  __block LTMaskedBlurProcessor *processor;
  __block LTTexture *mask;
  __block LTTexture *input;
  __block LTTexture *output;

  beforeEach(^{
    input = [LTTexture textureWithImage:LTLoadMat([self class], @"Lena128.png")];
    output = [LTTexture textureWithPropertiesOf:input];
    mask = [LTTexture byteRedTextureWithSize:kMaskSize];
    processor = [[LTMaskedBlurProcessor alloc] initWithInput:input blurMask:mask output:output];
  });

  afterEach(^{
    processor = nil;
    mask = nil;
    input = nil;
    output = nil;
  });

  context(@"initialization", ^{
    it(@"should initialize its properties with correct default values", ^{
      expect(processor.intensity).to.equal(1);
    });

    it(@"should set intensity correctly", ^{
      processor.intensity = 0.5;
      expect(processor.intensity).to.equal(0.5);
    });
  });

  context(@"processing", ^{
    context(@"constant mask", ^{
      it(@"should apply no blur when blurMask is nil", ^{
        processor = [[LTMaskedBlurProcessor alloc] initWithInput:input blurMask:nil output:output];

        [processor process];
        expect($(output.image)).to.beCloseToMat($(input.image));
      });

      /// blurMask is inverted and values above 0.5 are clipped.
      it(@"should apply no blur when blurMask contains ones", ^{
        [mask clearColor:LTVector4::ones()];

        [processor process];
        expect($(output.image)).to.beCloseToMat($(input.image));
      });

      it(@"should apply maximum blur when blurMask contains zeros", ^{
        [mask clearColor:LTVector4::zeros()];

        [processor process];

        cv::Mat expected = LTLoadMat([self class], @"BlurIntensityMax.png");
        expect($(output.image)).to.beCloseToMatPSNR($(expected), 45);
      });
    });

    beforeEach(^{
      [mask mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        mapped->at<uchar>(0, 0) = (uchar)(0.1 * 255);
        mapped->at<uchar>(0, 1) = (uchar)(0.2 * 255);
        mapped->at<uchar>(1, 0) = (uchar)(0.3 * 255);
        mapped->at<uchar>(1, 1) = (uchar)(0.4 * 255);
      }];

    });

    it(@"should apply blur correctly with default intensity", ^{
      processor.intensity = 1;
      [processor process];

      cv::Mat expected = LTLoadMat([self class], @"BlurIntensity1.png");
      expect($(output.image)).to.beCloseToMatPSNR($(expected), 50);
    });

    it(@"should apply blur correctly with half intencity", ^{
      processor.intensity = 0.5;
      [processor process];

      cv::Mat expected = LTLoadMat([self class], @"BlurIntensity0.5.png");
      expect($(output.image)).to.beCloseToMatPSNR($(expected), 50);
    });

    it(@"should apply blur with user mask", ^{
      LTTexture *userMask = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(2)];
      [userMask mappedImageForWriting:^(cv::Mat * mapped, BOOL) {
        mapped->at<uchar>(0, 0) = 0;
        mapped->at<uchar>(1, 0) = 255;
        mapped->at<uchar>(0, 1) = 255;
        mapped->at<uchar>(1, 1) = 0;
      }];

      processor = [[LTMaskedBlurProcessor alloc] initWithInput:input mask:userMask blurMask:mask
                                                        output:output];

      [processor process];
      cv::Mat expected = LTLoadMat([self class], @"BlurWithUserMaskIntensity1.png");
      expect($(output.image)).to.beCloseToMatPSNR($(expected), 50);
    });

    it(@"should apply blur correctly after input changes", ^{
      processor.intensity = 1;
      [processor process];

      cv::Mat bwLenaMat = LTLoadMat([self class], @"Lena128BWTonality.png");
      LTTexture *bwLena = [LTTexture textureWithImage:bwLenaMat];
      [bwLena cloneTo:processor.inputTexture];

      [processor process];

      LTTexture *expectedOutput = [LTTexture textureWithPropertiesOf:bwLena];
      LTMaskedBlurProcessor *referenceProcessor =
          [[LTMaskedBlurProcessor alloc] initWithInput:bwLena blurMask:mask output:expectedOutput];
      [referenceProcessor process];

      expect($(output.image)).to.beCloseToMat($(expectedOutput.image));
    });
  });
});

SpecEnd
