// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBoundaryExtractor.h"

#import "LTTexture+Factory.h"

SpecBegin(LTBoundaryExtractor)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
});

it(@"should produce correct result with white subrect", ^{
  cv::Mat4b image(32, 32, cv::Vec4b(0, 0, 0, 255));
  cv::Rect rect(16, 16, 8, 8);
  image(rect) = cv::Vec4b(255, 255, 255, 255);

  LTTexture *input = [LTTexture textureWithImage:image];
  LTTexture *output = [LTTexture textureWithPropertiesOf:input];

  LTBoundaryExtractor *processor = [[LTBoundaryExtractor alloc] initWithInput:input output:output];
  LTSingleTextureOutput *result = [processor process];

  // Draw the expected rect boundary.
  cv::Mat4b expected(image.size(), cv::Vec4b(0, 0, 0, 255));
  cv::Scalar white = cv::Scalar::all(255);
  cv::line(expected, rect.tl(), rect.tl() + cv::Point(0, rect.height - 1), white);
  cv::line(expected, rect.tl(), rect.tl() + cv::Point(rect.width - 1, 0), white);
  cv::line(expected, rect.br() - cv::Point(1, 1), rect.br() - cv::Point(rect.width, 1), white);
  cv::line(expected, rect.br() - cv::Point(1, 1), rect.br() - cv::Point(1, rect.height), white);

  expect(LTCompareMat(expected, [result.texture image])).to.beTruthy();
});

it(@"should produce correct result with complete white rect", ^{
  cv::Mat4b image(32, 32, cv::Vec4b(255, 255, 255, 255));
  cv::Rect rect(0, 0, 32, 32);

  LTTexture *input = [LTTexture textureWithImage:image];
  LTTexture *output = [LTTexture textureWithPropertiesOf:input];

  LTBoundaryExtractor *processor = [[LTBoundaryExtractor alloc] initWithInput:input output:output];
  LTSingleTextureOutput *result = [processor process];

  // Draw the expected rect boundary.
  cv::Mat4b expected(image.size(), cv::Vec4b(0, 0, 0, 255));
  cv::Scalar white = cv::Scalar::all(255);
  cv::line(expected, rect.tl(), rect.tl() + cv::Point(0, rect.height - 1), white);
  cv::line(expected, rect.tl(), rect.tl() + cv::Point(rect.width - 1, 0), white);
  cv::line(expected, rect.br() - cv::Point(1, 1), rect.br() - cv::Point(rect.width, 1), white);
  cv::line(expected, rect.br() - cv::Point(1, 1), rect.br() - cv::Point(1, rect.height), white);

  expect(LTCompareMat(expected, [result.texture image])).to.beTruthy();
});

SpecEnd
