// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTAspectFillResizeProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTAspectFillResizeProcessor)

it(@"should aspect fit image correctly", ^{
  cv::Mat image(LTLoadMat([self class], @"Flower.png"));

  LTTexture *inputTexture = [LTTexture textureWithImage:image];
  LTTexture *outputTexture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(32)];

  LTAspectFillResizeProcessor *processor = [[LTAspectFillResizeProcessor alloc]
                                            initWithInput:inputTexture andOutput:outputTexture];
  [processor process];

  cv::Mat expected(LTLoadMat([self class], @"AspectFittedFlower.png"));
  expect($([outputTexture image])).to.equalMat($(expected));
});

SpecEnd
