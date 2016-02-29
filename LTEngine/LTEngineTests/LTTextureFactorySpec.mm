// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture+Factory.h"

#import "LTCVPixelBufferExtensions.h"

SpecBegin(LTTextureFactory)

/// Since the class is currently decided in compile time, only verify that the class methods are
/// correctly called and that the returned object is indeed a texture class.

it(@"should initialize with size pixel format max mipmap level and allocate memory", ^{
  LTTexture *texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                      pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                   maxMipmapLevel:0
                                   allocateMemory:YES];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize with size pixel format and allocate memory", ^{
  LTTexture *texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                      pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                   allocateMemory:YES];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize with image", ^{
  cv::Mat4b image(1, 1);

  LTTexture *texture = [LTTexture textureWithImage:image];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize as rgba texture", ^{
  LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 1)];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize with properties of another texture", ^{
  LTTexture *another = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 1)];
  LTTexture *texture = [LTTexture textureWithPropertiesOf:another];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize mipmap with base image", ^{
  LTTexture *texture = [LTTexture textureWithBaseLevelMipmapImage:cv::Mat4b(1, 1)];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize mipmap with multiple images", ^{
  Matrices images{cv::Mat4b(8, 8), cv::Mat4b(4, 4), cv::Mat4b(2, 2), cv::Mat4b(1, 1)};
  LTTexture *texture = [LTTexture textureWithMipmapImages:images];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize with pixel buffer", ^{
  auto pixelBuffer = LTCVPixelBufferCreate(1, 1, kCVPixelFormatType_32BGRA);
  LTTexture *texture = [LTTexture textureWithPixelBuffer:pixelBuffer.get()];

  expect(texture).to.beKindOf([LTTexture class]);
});

it(@"should initialize with planar pixel buffer", ^{
  auto pixelBuffer = LTCVPixelBufferCreate(2, 2, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange);
  LTTexture *plane0 = [LTTexture textureWithPixelBuffer:pixelBuffer.get() planeIndex:0];
  LTTexture *plane1 = [LTTexture textureWithPixelBuffer:pixelBuffer.get() planeIndex:1];

  expect(plane0).to.beKindOf([LTTexture class]);
  expect(plane1).to.beKindOf([LTTexture class]);
});

SpecEnd
