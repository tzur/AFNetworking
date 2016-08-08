// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGLPixelFormat.h"

SpecBegin(LTGLPixelFormat)

static NSString * const kLTGLPixelFormatExamples = @"LTGLPixelFormatExamples";

sharedExamplesFor(kLTGLPixelFormatExamples, ^(NSDictionary *contextInfo) {
  __block LTGLVersion version;

  beforeEach(^{
    version = (LTGLVersion)[contextInfo[@"version"] unsignedIntegerValue];
  });

  it(@"should initialize with all supported texture internal formats", ^{
    [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *format) {
      GLenum internalFormat = [format textureInternalFormatForVersion:version];
      LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc]
                                      initWithTextureInternalFormat:internalFormat
                                      version:version];
      expect([pixelFormat textureInternalFormatForVersion:version]).to.equal(internalFormat);
    }];
  });

  it(@"should initialize with renderbuffer internal format LTGLPixelFormatRGBA8Unorm", ^{
    LTGLPixelFormat *format = $(LTGLPixelFormatRGBA8Unorm);
    GLenum internalFormat = [format renderbufferInternalFormatForVersion:version];
    LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc]
                                    initWithRenderbufferInternalFormat:internalFormat
                                    version:version];
    expect([pixelFormat renderbufferInternalFormatForVersion:version]).to.equal(internalFormat);
  });

  it(@"should return valid OpenGL format for all pixel formats", ^{
    [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
      expect([pixelFormat formatForVersion:version]).notTo.equal(LTGLInvalidEnum);
    }];
  });

  it(@"should return valid OpenGL precision for all pixel formats", ^{
    [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
      expect([pixelFormat precisionForVersion:version]).notTo.equal(LTGLInvalidEnum);
    }];
  });

  it(@"should return valid OpenGL texture internal format for all pixel formats", ^{
    [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
      expect([pixelFormat textureInternalFormatForVersion:version]).notTo.equal(LTGLInvalidEnum);
    }];
  });

  it(@"should return valid OpenGL renderbuffer internal format for LTGLPixelFormatRGBA8Unorm", ^{
    LTGLPixelFormat *pixelFormat = $(LTGLPixelFormatRGBA8Unorm);
    expect([pixelFormat textureInternalFormatForVersion:version]).notTo.equal(LTGLInvalidEnum);
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
});

itShouldBehaveLike(kLTGLPixelFormatExamples, @{@"version": @(LTGLVersion2)});
itShouldBehaveLike(kLTGLPixelFormatExamples, @{@"version": @(LTGLVersion3)});

SpecEnd
