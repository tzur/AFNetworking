// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTAspectFillResizeProcessor.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTAspectFillResizeProcessor)

it(@"should aspect fit image correctly", ^{
  cv::Mat image(LTLoadMat([self class], @"Flower.png"));

  LTTexture *inputTexture = [LTTexture textureWithImage:image];
  LTTexture *outputTexture = [LTTexture textureWithSize:CGSizeMake(32, 32)
                                              precision:LTTexturePrecisionByte
                                                 format:LTTextureFormatRGBA
                                         allocateMemory:YES];

  LTAspectFillResizeProcessor *processor = [[LTAspectFillResizeProcessor alloc]
                                            initWithInput:inputTexture andOutput:outputTexture];
  [processor process];

  cv::Mat expected(LTLoadMat([self class], @"AspectFittedFlower.png"));
  expect($([outputTexture image])).to.equalMat($(expected));
});

LTSpecEnd
