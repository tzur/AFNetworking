// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKInpaintingHighFrequencyTransfer.h"

#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/NSBundle+Path.h>

SpecBegin(PNKInpaintingHighFrequencyTransfer)

it(@"should not raise when the hole touches the boundary in the top-left corner", ^{
  cv::Mat4b inputMat(1024, 1024, cv::Scalar::all(127));

  cv::Mat1b maskMat(inputMat.size(), (uchar)0);
  maskMat(cv::Rect(0, 0, 30, 30)) = (uchar)255;

  cv::Mat4b lowFrequencyMat(512, 512, cv::Scalar::all(127));

  __block cv::Mat4b outputMat;

  expect(^{
    pnk_inpainting::transferHighFrequency(inputMat, maskMat, lowFrequencyMat, &outputMat);
  }).toNot.raiseAny();
});

it(@"should not raise when the hole touches the boundary in the bottom-right corner", ^{
  cv::Mat4b inputMat(1024, 1024, cv::Scalar::all(127));

  cv::Mat1b maskMat(inputMat.size(), (uchar)0);
  maskMat(cv::Rect(maskMat.cols - 30, maskMat.rows - 30, 30, 30)) = (uchar)255;

  cv::Mat4b lowFrequencyMat(512, 512, cv::Scalar::all(127));

  __block cv::Mat4b outputMat;

  expect(^{
    pnk_inpainting::transferHighFrequency(inputMat, maskMat, lowFrequencyMat, &outputMat);
  }).toNot.raiseAny();
});

it(@"should raise when the hole is empty", ^{
  cv::Mat4b inputMat(1024, 1024, cv::Scalar::all(127));
  cv::Mat1b maskMat(inputMat.size(), (uchar)0);
  cv::Mat4b lowFrequencyMat(512, 512, cv::Scalar::all(127));
  __block cv::Mat4b outputMat;

  expect(^{
    pnk_inpainting::transferHighFrequency(inputMat, maskMat, lowFrequencyMat, &outputMat);
  }).to.raise(NSInvalidArgumentException);
});

it(@"should not raise when one of the hole sides is less than 5 after resizing to low-frequency "
   "scale", ^{
  cv::Mat4b inputMat(1024, 1024, cv::Scalar::all(127));

  cv::Mat1b maskMat(inputMat.size(), (uchar)0);
  maskMat(cv::Rect(maskMat.cols / 2, maskMat.rows / 2, 8, 8)) = (uchar)255;

  cv::Mat4b lowFrequencyMat(512, 512, cv::Scalar::all(127));

  __block cv::Mat4b outputMat;

  expect(^{
    pnk_inpainting::transferHighFrequency(inputMat, maskMat, lowFrequencyMat, &outputMat);
  }).toNot.raiseAny();
});

it(@"should raise when the mask size does not match the input size", ^{
  cv::Mat4b inputMat(1024, 1024, cv::Scalar::all(127));

  cv::Mat1b maskMat(1025, 1025, (uchar)0);
  maskMat(cv::Rect(0, 0, maskMat.cols / 4, maskMat.rows / 4)) = (uchar)255;

  cv::Mat4b lowFrequencyMat(512, 512, cv::Scalar::all(127));

  __block cv::Mat4b outputMat;

  expect(^{
    pnk_inpainting::transferHighFrequency(inputMat, maskMat, lowFrequencyMat, &outputMat);
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise when the low frequency size is greater than the input size", ^{
  cv::Mat4b inputMat(1024, 1024, cv::Scalar::all(127));

  cv::Mat1b maskMat(1024, 1024, (uchar)0);
  maskMat(cv::Rect(0, 0, maskMat.cols / 4, maskMat.rows / 4)) = (uchar)255;

  cv::Mat4b lowFrequencyMat(2048, 2048, cv::Scalar::all(127));

  __block cv::Mat4b outputMat;

  expect(^{
    pnk_inpainting::transferHighFrequency(inputMat, maskMat, lowFrequencyMat, &outputMat);
  }).to.raise(NSInvalidArgumentException);
});

it(@"should transfer high frequency correctly", ^{
  auto bundle = NSBundle.lt_testBundle;

  cv::Mat4b inputMat = LTLoadMatFromBundle(bundle, @"bayInput.png");
  cv::Mat1b maskMat = LTLoadMatFromBundle(bundle, @"bayMask.png");
  cv::Mat4b lowFrequencyMat = LTLoadMatFromBundle(bundle, @"bayLowFrequency.png");
  cv::Mat4b outputMat;

  pnk_inpainting::transferHighFrequency(inputMat, maskMat, lowFrequencyMat, &outputMat);

  cv::Mat4b expectedMat = LTLoadMatFromBundle(bundle, @"bayOutput.png");
  expect($(outputMat)).to.equalMat($(expectedMat));
});

SpecEnd
