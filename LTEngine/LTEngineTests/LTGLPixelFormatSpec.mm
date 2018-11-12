// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLPixelFormat.h"

SpecBegin(LTGLPixelFormat)

it(@"should initialize with all supported texture internal formats", ^{
  [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *format) {
    GLenum internalFormat = format.textureInternalFormat;
    LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc]
                                    initWithTextureInternalFormat:internalFormat];
    expect(pixelFormat.textureInternalFormat).to.equal(internalFormat);
  }];
});

it(@"should initialize with renderbuffer internal format LTGLPixelFormatRGBA8Unorm", ^{
  LTGLPixelFormat *format = $(LTGLPixelFormatRGBA8Unorm);
  GLenum internalFormat = format.renderbufferInternalFormat;
  LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc]
                                  initWithRenderbufferInternalFormat:internalFormat];
  expect(pixelFormat.renderbufferInternalFormat).to.equal(internalFormat);
});

it(@"should initialize with components, bit depth and data type correctly", ^{
  [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *expected) {
    LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc] initWithComponents:expected.components
                                                                      dataType:expected.dataType];
    expect(pixelFormat).to.equal(expected);
  }];
});

it(@"should initialize with all supported metal pixel formats", ^{
  [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *format) {
    if (format.value == LTGLPixelFormatDepth16Unorm) {
      // No Metal equivalent format in iOS.
      return;
    }
    auto mtlPixelFormat = format.mtlPixelFormat;
    LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc] initWithMTLPixelFormat:mtlPixelFormat];
    expect(pixelFormat.mtlPixelFormat).to.equal(mtlPixelFormat);
  }];
});

it(@"should return valid metal pixel format for all pixel formats", ^{
  [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
    expect(pixelFormat.format).notTo.equal(MTLPixelFormatInvalid);
  }];
});

it(@"should return valid OpenGL format for all pixel formats", ^{
  [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
    expect(pixelFormat.format).notTo.equal(LTGLInvalidEnum);
  }];
});

it(@"should return valid OpenGL texture internal format for all pixel formats", ^{
  [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
    expect(pixelFormat.textureInternalFormat).notTo.equal(LTGLInvalidEnum);
  }];
});

it(@"should return valid OpenGL renderbuffer internal format for LTGLPixelFormatRGBA8Unorm", ^{
  LTGLPixelFormat *pixelFormat = $(LTGLPixelFormatRGBA8Unorm);
  expect(pixelFormat.textureInternalFormat).notTo.equal(LTGLInvalidEnum);
});

it(@"should initialize with all supported mat types", ^{
  for (int matType : [LTGLPixelFormat supportedMatTypes]) {
    LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc] initWithMatType:matType];
    expect(pixelFormat.matType).to.equal(matType);
  }
});

it(@"should initialize with all supported CVPixelFormatTypes", ^{
  for (OSType formatType : [LTGLPixelFormat supportedCVPixelFormatTypes]) {
    LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc] initWithCVPixelFormatType:formatType];
    expect(pixelFormat.cvPixelFormatType).to.equal(formatType);
  }
});

it(@"should initialize with all supported planar CVPixelFormatTypes", ^{
  for (OSType formatType : [LTGLPixelFormat supportedPlanarCVPixelFormatTypes]) {
    expect(^{
      LTGLPixelFormat __unused *pixelFormat =
          [[LTGLPixelFormat alloc] initWithPlanarCVPixelFormatType:formatType planeIndex:0];
    }).toNot.raiseAny();
  }
});

it(@"should provide cvPixelFormatType for all pixel formats", ^{
  [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
    expect(pixelFormat.cvPixelFormatType).notTo.equal(kUnknownType);
  }];
});

it(@"should provide matTypeCIFormat for all pixel formats", ^{
  [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
    expect(pixelFormat.ciFormatForMatType).notTo.equal(kUnknownType);
  }];
});

it(@"should provide cvPixelBufferTypeCIFormat for all pixel formats", ^{
  [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
    expect(pixelFormat.ciFormatForCVPixelFormatType).notTo.equal(kUnknownType);
  }];
});

it(@"should return correct channels count for all pixel formats", ^{
  [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
    NSUInteger expectedChannels;
    switch (pixelFormat.components) {
      case LTGLPixelComponentsR:
      case LTGLPixelComponentsDepth:
        expectedChannels = 1;
        break;
      case LTGLPixelComponentsRG:
        expectedChannels = 2;
        break;
      case LTGLPixelComponentsRGBA:
        expectedChannels = 4;
        break;
    }
    expect(pixelFormat.channels).to.equal(expectedChannels);
  }];
});

SpecEnd
