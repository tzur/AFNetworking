// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImage+Texture.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

SpecBegin(LTImage_Texture)

it(@"should create texture from RGBA image", ^{
  UIImage *image = LTLoadImage([self class], @"RectUp.jpg");
  LTTexture *texture = [LTImage textureWithImage:image];
  LTImage *ltImage = [[LTImage alloc] initWithImage:image];

  expect(texture.pixelFormat).to.equal($(LTGLPixelFormatRGBA8Unorm));
  expect($([texture image])).to.equalMat($(ltImage.mat));
});

it(@"should create texture from gray image", ^{
  UIImage *image = LTLoadImage([self class], @"Gray.jpg");
  LTTexture *texture = [LTImage textureWithImage:image];
  LTImage *ltImage = [[LTImage alloc] initWithImage:image];

  expect(texture.pixelFormat).to.equal($(LTGLPixelFormatR8Unorm));
  expect($([texture image])).to.equalMat($(ltImage.mat));
});

it(@"should load image to existing texture", ^{
  UIImage *image = LTLoadImage([self class], @"Gray.jpg");
  LTTexture *texture = [LTTexture byteRedTextureWithSize:image.size];
  [LTImage loadImage:image toTexture:texture];

  LTImage *ltImage = [[LTImage alloc] initWithImage:image];

  expect($([texture image])).to.equalMat($(ltImage.mat));
});

it(@"should not load image to invalid texture format", ^{
  UIImage *image = LTLoadImage([self class], @"Gray.jpg");
  LTTexture *texture = [LTTexture byteRGBATextureWithSize:image.size];
  expect(^{
    [LTImage loadImage:image toTexture:texture];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should not load image to invalid texture size", ^{
  UIImage *image = LTLoadImage([self class], @"Gray.jpg");
  LTTexture *texture = [LTTexture byteRedTextureWithSize:image.size * 2];
  expect(^{
    [LTImage loadImage:image toTexture:texture];
  }).to.raise(NSInvalidArgumentException);
});

SpecEnd
