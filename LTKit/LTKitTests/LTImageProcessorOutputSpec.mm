// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessorOutput.h"

#import "LTGLTexture.h"
#import "LTSplitComplexMat.h"

static LTTexture *LTCreateTexture() {
  return [[LTGLTexture alloc] initByteRGBAWithSize:CGSizeMake(1, 1)];
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

SpecBegin(LTSingleMatOutput)

it(@"should initialize and set properties", ^{
  cv::Mat4b mat(cv::Mat4b::zeros(16, 16));
  LTSingleMatOutput *output = [[LTSingleMatOutput alloc] initWithMat:mat];

  expect($(output.mat)).to.equalMat($(mat));
});

SpecEnd

SpecBegin(LTSplitComplexMatOutput)

it(@"should initialize and set properties", ^{
  cv::Mat1f real(cv::Mat1f::zeros(16, 16));
  cv::Mat1f imag(cv::Mat1f::ones(16, 16));

  LTSplitComplexMat *splitComplexMat = [[LTSplitComplexMat alloc] initWithReal:real imag:imag];
  LTSplitComplexMatOutput *output = [[LTSplitComplexMatOutput alloc]
                                     initWithSplitComplexMat:splitComplexMat];

  expect($(output.splitComplexMat.real)).to.equalMat($(real));
  expect($(output.splitComplexMat.imag)).to.equalMat($(imag));
});

SpecEnd