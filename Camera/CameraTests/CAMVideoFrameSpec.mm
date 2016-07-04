// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMVideoFrame.h"

#import <LTEngine/LTTexture+Factory.h>

#import "CAMDevicePreset.h"

SpecBegin(CAMVideoFrame)

context(@"Y'CbCr", ^{
  __block LTTexture *yTexture;
  __block LTTexture *cbcrTexture;

  beforeEach(^{
    yTexture = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                              pixelFormat:$(LTGLPixelFormatR8Unorm) allocateMemory:NO];
    cbcrTexture = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                 pixelFormat:$(LTGLPixelFormatRG8Unorm) allocateMemory:NO];
  });

  afterEach(^{
    yTexture = nil;
    cbcrTexture = nil;
  });

  context(@"init", ^{
    it(@"should not raise when initializing with valid pair", ^{
      expect(^{
        __unused id frame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture
                                                             cbcrTexture:cbcrTexture];
      }).toNot.raiseAny();
    });

    it(@"should init properties correctly", ^{
      CAMVideoFrameYCbCr *frame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture
                                                                   cbcrTexture:cbcrTexture];
      expect(frame.pixelFormat).to.equal($(CAMPixelFormat420f));
      expect(frame.textures).to.equal(@[yTexture, cbcrTexture]);
      expect(frame.yTexture).to.equal(yTexture);
      expect(frame.cbcrTexture).to.equal(cbcrTexture);
    });

    it(@"should raise when initializing with nil textures", ^{
      expect(^{
        LTTexture *texture = nil;
        __unused id frame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:texture
                                                             cbcrTexture:cbcrTexture];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        LTTexture *texture = nil;
        __unused id frame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture
                                                             cbcrTexture:texture];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when initializing with wrong texture format", ^{
      expect(^{
        __unused id frame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:cbcrTexture
                                                             cbcrTexture:cbcrTexture];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        __unused id frame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture
                                                             cbcrTexture:yTexture];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"NSObject", ^{
    __block CAMVideoFrameYCbCr *frame;
    __block CAMVideoFrameYCbCr *sameFrame;
    __block CAMVideoFrameYCbCr *otherFrame;

    beforeEach(^{
      frame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture cbcrTexture:cbcrTexture];
      sameFrame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture cbcrTexture:cbcrTexture];

      LTTexture *texture = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                          pixelFormat:$(LTGLPixelFormatRG8Unorm)
                                       allocateMemory:NO];
      otherFrame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture cbcrTexture:texture];
    });

    it(@"should handle isEqual correctly", ^{
      expect(frame).to.equal(sameFrame);
      expect(frame).toNot.equal(otherFrame);
      expect(sameFrame).toNot.equal(otherFrame);
    });

    it(@"should handle hash correctly", ^{
      expect(frame.hash).to.equal(sameFrame.hash);
    });
  });
});

context(@"BGRA", ^{
  __block LTTexture *bgraTexture;
  __block LTTexture *otherTexture;

  beforeEach(^{
    bgraTexture = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                 pixelFormat:$(LTGLPixelFormatRGBA8Unorm) allocateMemory:NO];
    otherTexture = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                  pixelFormat:$(LTGLPixelFormatRG8Unorm) allocateMemory:NO];
  });

  context(@"init", ^{
    it(@"should not raise when initializing with valid texture", ^{
      expect(^{
        __unused id frame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:bgraTexture];
      }).toNot.raiseAny();
    });

    it(@"should init properties correctly", ^{
      CAMVideoFrameBGRA *frame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:bgraTexture];
      expect(frame.pixelFormat).to.equal($(CAMPixelFormatBGRA));
      expect(frame.textures).to.equal(@[bgraTexture]);
      expect(frame.bgraTexture).to.equal(bgraTexture);
    });

    it(@"should raise when initializing with nil textures", ^{
      expect(^{
        LTTexture *texture = nil;
        __unused id frame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:texture];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when initializing with wrong texture format", ^{
      expect(^{
        __unused id frame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:otherTexture];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"NSObject", ^{
    __block CAMVideoFrameBGRA *frame;
    __block CAMVideoFrameBGRA *sameFrame;
    __block CAMVideoFrameBGRA *otherFrame;

    beforeEach(^{
      frame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:bgraTexture];
      sameFrame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:bgraTexture];

      LTTexture *texture = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                          pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                       allocateMemory:NO];
      otherFrame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:texture];
    });

    it(@"should handle isEqual correctly", ^{
      expect(frame).to.equal(sameFrame);
      expect(frame).toNot.equal(otherFrame);
      expect(sameFrame).toNot.equal(otherFrame);
    });

    it(@"should handle hash correctly", ^{
      expect(frame.hash).to.equal(sameFrame.hash);
    });
  });
});

SpecEnd
