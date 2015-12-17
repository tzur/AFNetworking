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

  it(@"should initialize with all supported internal formats", ^{
    [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *format) {
      GLenum internalFormat = [format internalFormatForVersion:version];
      LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc] initWithInternalFormat:internalFormat
                                                                             version:version];
      expect([pixelFormat internalFormatForVersion:version]).to.equal(internalFormat);
    }];
  });

  it(@"should return valid OpenGL format for all pixel formats", ^{
    [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
      expect([pixelFormat formatForVersion:version]).toNot.equal(LTGLInvalidEnum);
    }];
  });

  it(@"should return valid OpenGL precision for all pixel formats", ^{
    [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
      expect([pixelFormat precisionForVersion:version]).toNot.equal(LTGLInvalidEnum);
    }];
  });

  it(@"should return valid OpenGL internal format for all pixel formats", ^{
    [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
      expect([pixelFormat internalFormatForVersion:version]).toNot.equal(LTGLInvalidEnum);
    }];
  });
});

it(@"should initialize with all supported mat types", ^{
  for (int matType : [LTGLPixelFormat supportedMatTypes]) {
    LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc] initWithMatType:matType];
    expect(pixelFormat.matType).to.equal(matType);
  }
});

it(@"should provide cvPixelFormatType for all pixel formats", ^{
  [LTGLPixelFormat enumerateEnumUsingBlock:^(LTGLPixelFormat *pixelFormat) {
    expect(pixelFormat.cvPixelFormatType).toNot.equal(kUnknownType);
  }];
});

itShouldBehaveLike(kLTGLPixelFormatExamples, @{@"version": @(LTGLVersion2)});
itShouldBehaveLike(kLTGLPixelFormatExamples, @{@"version": @(LTGLVersion3)});

SpecEnd
