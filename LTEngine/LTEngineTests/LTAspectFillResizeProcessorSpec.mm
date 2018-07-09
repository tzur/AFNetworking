// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTAspectFillResizeProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTAspectFillResizeProcessor)

__block LTTexture *outputTexture;
__block LTAspectFillResizeProcessor *processor;

beforeEach(^{
  cv::Mat image(LTLoadMat([self class], @"Flower.png"));

  auto inputTexture = [LTTexture textureWithImage:image];
  outputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(32)];

  processor = [[LTAspectFillResizeProcessor alloc] initWithInput:inputTexture
                                                       andOutput:outputTexture];
});

afterEach(^{
  outputTexture = nil;
  processor = nil;
});

it(@"it should have correct interpolation quality by default", ^{
  expect(processor.interpolationQuality).to.equal(kCGInterpolationHigh);
});

it(@"should aspect fill image correctly", ^{
  [processor process];
  cv::Mat expected(LTLoadMat([self class], @"AspectFittedFlower.png"));
  expect($([outputTexture image])).to.equalMat($(expected));

  processor.interpolationQuality = kCGInterpolationLow;
  [processor process];
  expected = cv::Mat(LTLoadMat([self class], @"AspectFittedFlowerLowQuality.png"));
  expect($([outputTexture image])).to.equalMat($(expected));
});

it(@"should clear previously used texture properly", ^{
  cv::Mat4b checkerboard =
      LTCheckerboardPattern(CGSizeMakeUniform(80), 20, cv::Vec4b (193, 193, 193, 255),
                            cv::Vec4b (255, 255, 255, 122));
  auto inputTexture = [LTTexture textureWithImage:checkerboard];

  auto processor = [[LTAspectFillResizeProcessor alloc] initWithInput:inputTexture
                                                            andOutput:outputTexture];
  [processor process];

  cv::Mat expected(LTLoadMat([self class], @"AspectFittedHalfTransparent.png"));
  expect($([outputTexture image])).to.equalMat($(expected));
});

SpecEnd
