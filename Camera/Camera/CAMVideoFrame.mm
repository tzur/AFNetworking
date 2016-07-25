// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMVideoFrame.h"

#import <LTEngine/LTTexture.h>

#import "CAMDevicePreset.h"
#import "CAMSampleTimingInfo.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *CAMSampleTimingInfoString(CMSampleTimingInfo sampleTimingInfo) {
  return [NSString stringWithFormat:@"{%g, %g, %g}", CMTimeGetSeconds(sampleTimingInfo.duration),
      CMTimeGetSeconds(sampleTimingInfo.presentationTimeStamp),
      CMTimeGetSeconds(sampleTimingInfo.decodeTimeStamp)];
}

@implementation CAMVideoFrameYCbCr

@synthesize sampleTimingInfo = _sampleTimingInfo;

- (instancetype)initWithYTexture:(LTTexture *)yTexture cbcrTexture:(LTTexture *)cbcrTexture
                sampleTimingInfo:(CMSampleTimingInfo)sampleTimingInfo {
  LTParameterAssert(yTexture, @"Y' texture can't be nil");
  LTParameterAssert(yTexture.pixelFormat.value == LTGLPixelFormatR8Unorm,
      @"Y' texture must be R8Unorm");
  LTParameterAssert(cbcrTexture, @"CbCr texture can't be nil");
  LTParameterAssert(cbcrTexture.pixelFormat.value == LTGLPixelFormatRG8Unorm,
      @"CbCr texture must be RG8Unorm");
  if (self = [super init]) {
    _yTexture = yTexture;
    _cbcrTexture = cbcrTexture;
    _sampleTimingInfo = sampleTimingInfo;
  }
  return self;
}

- (CAMPixelFormat *)pixelFormat {
  return $(CAMPixelFormat420f);
}

- (NSArray<LTTexture *> *)textures {
  return @[self.yTexture, self.cbcrTexture];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, yTexture: %@, cbcrTexture: %@, sampleTimingInfo: "
          "%@>", [self class], self, self.yTexture, self.cbcrTexture,
          CAMSampleTimingInfoString(self.sampleTimingInfo)];
}

- (BOOL)isEqual:(CAMVideoFrameYCbCr *)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[self class]]) {
    return NO;
  }

  return [self.yTexture isEqual:other.yTexture] && [self.cbcrTexture isEqual:other.cbcrTexture] &&
      CAMSampleTimingInfoIsEqual(self.sampleTimingInfo, other.sampleTimingInfo);
}

- (NSUInteger)hash {
  return self.yTexture.hash ^ self.cbcrTexture.hash ^
      CAMSampleTimingInfoHash(self.sampleTimingInfo);
}

@end

@implementation CAMVideoFrameBGRA

@synthesize sampleTimingInfo = _sampleTimingInfo;

- (instancetype)initWithBGRATexture:(LTTexture *)bgraTexture
                   sampleTimingInfo:(CMSampleTimingInfo)sampleTimingInfo{
  LTParameterAssert(bgraTexture, @"BGRA texture can't be nil");
  LTParameterAssert(bgraTexture.pixelFormat.value == LTGLPixelFormatRGBA8Unorm,
      @"BGRA texture must be RGBA8Unorm");
  if (self = [super init]) {
    _bgraTexture = bgraTexture;
    _sampleTimingInfo = sampleTimingInfo;
  }
  return self;
}

- (CAMPixelFormat *)pixelFormat {
  return $(CAMPixelFormatBGRA);
}

- (NSArray<LTTexture *> *)textures {
  return @[self.bgraTexture];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, bgraTexture: %@, sampleTimingInfo: %@>",
          [self class], self, self.bgraTexture, CAMSampleTimingInfoString(self.sampleTimingInfo)];
}

- (BOOL)isEqual:(CAMVideoFrameBGRA *)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[self class]]) {
    return NO;
  }

  return [self.bgraTexture isEqual:other.bgraTexture] &&
      CAMSampleTimingInfoIsEqual(self.sampleTimingInfo, other.sampleTimingInfo);
}

- (NSUInteger)hash {
  return self.bgraTexture.hash ^ CAMSampleTimingInfoHash(self.sampleTimingInfo);
}

@end

NS_ASSUME_NONNULL_END
