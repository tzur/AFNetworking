// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTAspectFillResizeProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTAspectFillResizeProcessor)

__block LTTexture *outputTexture;

beforeEach(^{
  cv::Mat image(LTLoadMat([self class], @"Flower.png"));
  
  LTTexture *inputTexture = [LTTexture textureWithImage:image];
  outputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(32)];

  LTAspectFillResizeProcessor *processor = [[LTAspectFillResizeProcessor alloc]
                                            initWithInput:inputTexture andOutput:outputTexture];
  [processor process];
});

afterEach(^{
  outputTexture = nil;
});

it(@"should aspect fit image correctly", ^{
  cv::Mat expected(LTLoadMat([self class], @"AspectFittedFlower.png"));
  expect($([outputTexture image])).to.equalMat($(expected));
});

it(@"should clear previously used texture properly", ^{
  cv::Mat4b checkerboard =
      LTCheckerboardPattern(CGSizeMakeUniform(80), 20, cv::Vec4b (193, 193, 193, 255),
                            cv::Vec4b (255, 255, 255, 122));
  LTTexture *inputTexture = [LTTexture textureWithImage:checkerboard];

  LTAspectFillResizeProcessor *processor = [[LTAspectFillResizeProcessor alloc]
                                            initWithInput:inputTexture andOutput:outputTexture];
  [processor process];

  cv::Mat expected(LTLoadMat([self class], @"AspectFittedHalfTransparent.png"));
  expect($([outputTexture image])).to.equalMat($(expected));
});

SpecEnd
