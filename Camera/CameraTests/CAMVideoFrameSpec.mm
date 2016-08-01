// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMVideoFrame.h"

#import <LTEngine/LTTexture+Factory.h>

#import "CAMDevicePreset.h"
#import "CAMSampleTimingInfo.h"

SpecBegin(CAMVideoFrame)

__block CMSampleTimingInfo sampleTimingInfo;
__block CMSampleTimingInfo otherTimingInfo;

beforeEach(^{
  sampleTimingInfo = {kCMTimeZero, CMTimeMake(1, 60), kCMTimeZero};
  otherTimingInfo = {kCMTimeZero, CMTimeMake(2, 60), kCMTimeZero};
});

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
                                                             cbcrTexture:cbcrTexture
                                                        sampleTimingInfo:sampleTimingInfo];
      }).toNot.raiseAny();
    });

    it(@"should init properties correctly", ^{
      CAMVideoFrameYCbCr *frame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture
                                                                   cbcrTexture:cbcrTexture
                                                              sampleTimingInfo:sampleTimingInfo];
      expect(frame.pixelFormat).to.equal($(CAMPixelFormat420f));
      expect(frame.textures).to.equal(@[yTexture, cbcrTexture]);
      expect(frame.yTexture).to.equal(yTexture);
      expect(frame.cbcrTexture).to.equal(cbcrTexture);
      expect(CAMSampleTimingInfoIsEqual(frame.sampleTimingInfo, sampleTimingInfo)).to.beTruthy();
    });

    it(@"should raise when initializing with nil textures", ^{
      expect(^{
        LTTexture *texture = nil;
        __unused id frame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:texture
                                                             cbcrTexture:cbcrTexture
                                                        sampleTimingInfo:sampleTimingInfo];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        LTTexture *texture = nil;
        __unused id frame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture
                                                             cbcrTexture:texture
                                                        sampleTimingInfo:sampleTimingInfo];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when initializing with wrong texture format", ^{
      expect(^{
        __unused id frame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:cbcrTexture
                                                             cbcrTexture:cbcrTexture
                                                        sampleTimingInfo:sampleTimingInfo];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        __unused id frame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture
                                                             cbcrTexture:yTexture
                                                        sampleTimingInfo:sampleTimingInfo];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"NSObject", ^{
    __block CAMVideoFrameYCbCr *frame;
    __block CAMVideoFrameYCbCr *sameFrame;
    __block CAMVideoFrameYCbCr *otherFrame;
    __block CAMVideoFrameYCbCr *otherTimingInfoFrame;

    beforeEach(^{
      frame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture cbcrTexture:cbcrTexture
                                          sampleTimingInfo:sampleTimingInfo];
      sameFrame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture cbcrTexture:cbcrTexture
                                              sampleTimingInfo:sampleTimingInfo];

      LTTexture *texture = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                          pixelFormat:$(LTGLPixelFormatRG8Unorm)
                                       allocateMemory:NO];
      otherFrame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture cbcrTexture:texture
                                               sampleTimingInfo:sampleTimingInfo];
      otherTimingInfoFrame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture
                                                              cbcrTexture:cbcrTexture
                                                         sampleTimingInfo:otherTimingInfo];
    });

    it(@"should handle isEqual correctly", ^{
      expect(frame).to.equal(sameFrame);
      expect(frame).toNot.equal(otherFrame);
      expect(sameFrame).toNot.equal(otherFrame);
      expect(frame).toNot.equal(otherTimingInfoFrame);
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
        __unused id frame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:bgraTexture
                                                          sampleTimingInfo:sampleTimingInfo];
      }).toNot.raiseAny();
    });

    it(@"should init properties correctly", ^{
      CAMVideoFrameBGRA *frame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:bgraTexture
                                                               sampleTimingInfo:sampleTimingInfo];
      expect(frame.pixelFormat).to.equal($(CAMPixelFormatBGRA));
      expect(frame.textures).to.equal(@[bgraTexture]);
      expect(frame.bgraTexture).to.equal(bgraTexture);
      expect(CAMSampleTimingInfoIsEqual(frame.sampleTimingInfo, sampleTimingInfo)).to.beTruthy();
    });

    it(@"should raise when initializing with nil textures", ^{
      expect(^{
        LTTexture *texture = nil;
        __unused id frame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:texture
                                                          sampleTimingInfo:sampleTimingInfo];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when initializing with wrong texture format", ^{
      expect(^{
        __unused id frame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:otherTexture
                                                          sampleTimingInfo:sampleTimingInfo];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"NSObject", ^{
    __block CAMVideoFrameBGRA *frame;
    __block CAMVideoFrameBGRA *sameFrame;
    __block CAMVideoFrameBGRA *otherFrame;
    __block CAMVideoFrameBGRA *otherTimingInfoFrame;

    beforeEach(^{
      frame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:bgraTexture
                                            sampleTimingInfo:sampleTimingInfo];
      sameFrame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:bgraTexture
                                                sampleTimingInfo:sampleTimingInfo];

      LTTexture *texture = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                          pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                       allocateMemory:NO];
      otherFrame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:texture
                                                 sampleTimingInfo:sampleTimingInfo];
      otherTimingInfoFrame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:texture
                                                           sampleTimingInfo:otherTimingInfo];
    });

    it(@"should handle isEqual correctly", ^{
      expect(frame).to.equal(sameFrame);
      expect(frame).toNot.equal(otherFrame);
      expect(sameFrame).toNot.equal(otherFrame);
      expect(frame).toNot.equal(otherTimingInfoFrame);
    });

    it(@"should handle hash correctly", ^{
      expect(frame.hash).to.equal(sameFrame.hash);
    });
  });
});

SpecEnd
