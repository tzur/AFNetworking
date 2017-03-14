// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "LTFboAttachmentInfo.h"

#import "LTRenderbuffer.h"
#import "LTTexture+Factory.h"

SpecBegin(LTFboAttachmentInfoSpec)

it(@"should raise when initializing with renderbuffer with nonzero level", ^{
  auto drawable = [CAEAGLLayer layer];
  drawable.frame = CGRectMake(0, 0, 2, 3);
  auto renderbuffer = [[LTRenderbuffer alloc] initWithDrawable:drawable];

  __block LTFboAttachmentInfo *info;
  expect(^{
    info = [LTFboAttachmentInfo withAttachable:renderbuffer level:1];
  }).to.raise(NSInvalidArgumentException);
  expect(info).to.beNil();
});

it(@"should initialize properly with attachable", ^{
  auto texture = [LTTexture textureWithImage:cv::Mat(2, 3, CV_8UC1)];
  auto info = [LTFboAttachmentInfo withAttachable:texture];

  expect(info).notTo.beNil();
  expect(info.attachable).to.equal(texture);
  expect(info.level).to.equal(0);
});

it(@"should initialize properly with attachable and level", ^{
  Matrices images{cv::Mat4b(2, 2), cv::Mat4b(1, 1)};
  auto texture = [LTTexture textureWithMipmapImages:images];
  auto info = [LTFboAttachmentInfo withAttachable:texture level:1];

  expect(info).notTo.beNil();
  expect(info.attachable).to.equal(texture);
  expect(info.level).to.equal(1);
});

SpecEnd
