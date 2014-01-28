// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBoxFilterProcessor.h"

#import "LTTestUtils.h"
#import "LTTexture+Factory.h"

SpecBegin(LTBoxFilterProcessor)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

__block LTTexture *output;
__block LTBoxFilterProcessor *processor;

beforeEach(^{
  LTTexture *input = [LTTexture textureWithImage:LTCreateDeltaMat(CGSizeMake(7, 7))];
  output = [LTTexture byteRGBATextureWithSize:input.size];
  processor = [[LTBoxFilterProcessor alloc] initWithInput:input outputs:@[output]];
});

afterEach(^{
  output = nil;
  processor = nil;
});

it(@"should process input image correctly", ^{
  processor.iterationsPerOutput = @[@1];
  [processor process];

  // Result of 7x7 box filter on delta function is constant equal to: 255 / (7 x 7) ~ 5.2041.
  cv::Mat4b processedDelta(7, 7);
  processedDelta = cv::Vec4b(5, 5, 5, 255);

  expect(LTFuzzyCompareMat(processedDelta, [output image])).to.beTruthy();
});

SpecEnd
