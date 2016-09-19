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

it(@"should create texture from a transparent image", ^{
  UIImage *image = LTLoadImage([self class], @"BlueTransparent.png");
  LTTexture *texture = [LTImage textureWithImage:image backgroundColor:nil];
  LTImage *ltImage = [[LTImage alloc] initWithImage:image];

  expect(texture.pixelFormat).to.equal($(LTGLPixelFormatRGBA8Unorm));
  expect($([texture image])).to.equalMat($(ltImage.mat));
});

it(@"should create texture from a transparent image and a background color", ^{
  UIImage *image = LTLoadImage([self class], @"BlueTransparent.png");
  UIColor *color = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
  LTTexture *texture = [LTImage textureWithImage:image backgroundColor:color];
  LTImage *ltImage = [[LTImage alloc] initWithImage:image];

  // Calculated using normal blending, where:
  // rgb = Sca + Dca * (1.0 - Sa).
  // a = Sa + Da - Sa * Da.
  cv::Mat4b mat = ltImage.mat;
  std::transform(mat.begin(), mat.end(), mat.begin(), [](const cv::Vec4b &value) {
    double alpha = value[3] / 255.0;
    return cv::Vec4b(value[0] + (1 - alpha) * 127, value[1] + (1 - alpha) * 127,
                     value[2] + (1 - alpha) * 127, ((alpha + 0.5) - alpha * 0.5) * 255);
  });

  expect(texture.pixelFormat).to.equal($(LTGLPixelFormatRGBA8Unorm));
  expect($([texture image])).to.beCloseToMat($(mat));
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
