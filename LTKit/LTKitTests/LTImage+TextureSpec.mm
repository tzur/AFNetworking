// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImage+Texture.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture.h"

SpecGLBegin(LTImage_Texture)

it(@"should create texture from RGBA image", ^{
  UIImage *image = LTLoadImage([self class], @"RectUp.jpg");
  LTTexture *texture = [LTImage textureWithImage:image];
  LTImage *ltImage = [[LTImage alloc] initWithImage:image];

  expect(texture.precision).to.equal(LTTexturePrecisionByte);
  expect(texture.format).to.equal(LTTextureFormatRGBA);
  expect($([texture image])).to.equalMat($(ltImage.mat));
});

it(@"should create texture from gray image", ^{
  UIImage *image = LTLoadImage([self class], @"Gray.jpg");
  LTTexture *texture = [LTImage textureWithImage:image];
  LTImage *ltImage = [[LTImage alloc] initWithImage:image];

  expect(texture.precision).to.equal(LTTexturePrecisionByte);
  expect(texture.format).to.equal(LTTextureFormatRed);
  expect($([texture image])).to.equalMat($(ltImage.mat));
});

SpecGLEnd
