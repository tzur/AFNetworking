// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessorOutput.h"

#import "LTGLTexture.h"

static LTTexture *LTCreateTexture() {
  return [[LTGLTexture alloc] initWithSize:CGSizeMake(1, 1)
                                 precision:LTTexturePrecisionByte
                                  channels:LTTextureChannelsRGBA
                            allocateMemory:YES];
}

SpecBegin(LTSingleTextureOutput)

__block LTTexture *texture;

beforeEach(^{
  texture = LTCreateTexture();
});

afterEach(^{
  texture = nil;
});

it(@"should initialize and set properties", ^{
  LTSingleTextureOutput *output = [[LTSingleTextureOutput alloc] initWithTexture:texture];

  expect(output.texture).to.equal(texture);
});

SpecEnd

SpecBegin(LTMultipleTextureOutput)

__block LTTexture *texture;

beforeEach(^{
  texture = LTCreateTexture();
});

afterEach(^{
  texture = nil;
});

it(@"should initialize and set properties", ^{
  LTMultipleTextureOutput *output = [[LTMultipleTextureOutput alloc] initWithTextures:@[texture]];

  expect(output.textures).to.equal(@[texture]);
});

SpecEnd
