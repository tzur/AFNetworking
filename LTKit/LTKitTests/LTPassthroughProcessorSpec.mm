// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPassthroughProcessor.h"

#import "LTTexture+Factory.h"

SpecBegin(LTPassthroughProcessor)

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
});

afterEach(^{
  [LTGLContext setCurrentContext:nil];
});

it(@"should copy input to output", ^{
  cv::Mat4b image(16, 16, cv::Vec4b(128, 64, 32, 255));
  LTTexture *input = [LTTexture textureWithImage:image];
  LTTexture *output = [LTTexture textureWithPropertiesOf:input];

  LTPassthroughProcessor *processor = [[LTPassthroughProcessor alloc] initWithInput:input
                                                                             output:output];
  LTSingleTextureOutput *result = [processor process];

  expect($([result.texture image])).to.beCloseToMat($(image));
});

SpecEnd
