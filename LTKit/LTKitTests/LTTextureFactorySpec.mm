// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture+Factory.h"

SpecBegin(LTTextureFactory)

/// Since the class is currently decided in compile time, only verify that the class methods are
/// correctly called and that the returned object is indeed a texture class.

it(@"should initialize with size precision channels and allocate memory", ^{
  LTTexture *texture = [LTTexture textureWithSize:CGSizeMake(1, 1)
                                        precision:LTTexturePrecisionByte
                                         channels:LTTextureChannelsRGBA
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

SpecEnd
