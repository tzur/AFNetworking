// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture+Factory.h"

LTSpecBegin(LTTextureFactory)

/// Since the class is currently decided in compile time, only verify that the class methods are
/// correctly called and that the returned object is indeed a texture class.

it(@"should initialize with size precision channels and allocate memory", ^{
  LTTexture *texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                        precision:LTTexturePrecisionByte
                                           format:LTTextureFormatRGBA
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

LTSpecEnd
