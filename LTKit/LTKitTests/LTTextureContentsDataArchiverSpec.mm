// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureContentsDataArchiver.h"

#import "LTTexture+Factory.h"

SpecGLBegin(LTTextureContentsDataArchiver)

__block LTTexture *texture;
__block cv::Mat4b image;

beforeEach(^{
  image.create(2, 2);
  image(0, 0) = cv::Vec4b(255, 0, 0, 255);
  image(0, 1) = cv::Vec4b(0, 255, 0, 255);
  image(1, 0) = cv::Vec4b(0, 0, 255, 255);
  image(1, 1) = cv::Vec4b(0, 0, 0, 255);

  texture = [LTTexture textureWithImage:image];
});

afterEach(^{
  texture = nil;
});

it(@"should store and restore texture from data", ^{
  LTTextureContentsDataArchiver *archiver = [[LTTextureContentsDataArchiver alloc] init];

  __block NSError *error;
  NSData *data = [archiver archiveTexture:texture error:&error];

  expect(data).toNot.beNil();
  expect(error).to.beNil();

  expect([archiver unarchiveData:data toTexture:texture error:&error]).to.beTruthy();
  expect(error).to.beNil();
  expect($([texture image])).to.equalMat($(image));
});

SpecGLEnd
