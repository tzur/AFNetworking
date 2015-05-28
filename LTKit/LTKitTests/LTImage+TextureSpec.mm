// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImage+Texture.h"

#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(LTImage_Texture)

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

it(@"should load image to existing texture", ^{
  UIImage *image = LTLoadImage([self class], @"Gray.jpg");
  LTTexture *texture = [LTTexture textureWithSize:image.size precision:LTTexturePrecisionByte
                                           format:LTTextureFormatRed allocateMemory:YES];
  [LTImage loadImage:image toTexture:texture];

  LTImage *ltImage = [[LTImage alloc] initWithImage:image];

  expect($([texture image])).to.equalMat($(ltImage.mat));
});

it(@"should not load image to invalid texture format", ^{
  UIImage *image = LTLoadImage([self class], @"Gray.jpg");
  LTTexture *texture = [LTTexture textureWithSize:image.size precision:LTTexturePrecisionByte
                                           format:LTTextureFormatRGBA allocateMemory:YES];
  expect(^{
    [LTImage loadImage:image toTexture:texture];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should not load image to inavlid texture size", ^{
  UIImage *image = LTLoadImage([self class], @"Gray.jpg");
  LTTexture *texture = [LTTexture textureWithSize:image.size * 2 precision:LTTexturePrecisionByte
                                           format:LTTextureFormatRed allocateMemory:YES];
  expect(^{
    [LTImage loadImage:image toTexture:texture];
  }).to.raise(NSInvalidArgumentException);
});

LTSpecEnd
