// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMVideoFrame.h"

#import <LTEngine/LTTexture.h>

#import "CAMDevicePreset.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMVideoFrameYCbCr

- (instancetype)initWithYTexture:(LTTexture *)yTexture cbcrTexture:(LTTexture *)cbcrTexture {
  LTParameterAssert(yTexture, @"Y' texture can't be nil");
  LTParameterAssert(yTexture.pixelFormat.value == LTGLPixelFormatR8Unorm,
      @"Y' texture must be R8Unorm");
  LTParameterAssert(cbcrTexture, @"CbCr texture can't be nil");
  LTParameterAssert(cbcrTexture.pixelFormat.value == LTGLPixelFormatRG8Unorm,
      @"CbCr texture must be RG8Unorm");
  if (self = [super init]) {
    _yTexture = yTexture;
    _cbcrTexture = cbcrTexture;
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
  return [NSString stringWithFormat:@"<%@: %p, yTexture: %@, cbcrTexture: %@>", [self class], self,
          self.yTexture, self.cbcrTexture];
}

- (BOOL)isEqual:(CAMVideoFrameYCbCr *)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[self class]]) {
    return NO;
  }

  return [self.yTexture isEqual:other.yTexture] && [self.cbcrTexture isEqual:other.cbcrTexture];
}

- (NSUInteger)hash {
  return self.yTexture.hash ^ self.cbcrTexture.hash;
}

@end

@implementation CAMVideoFrameBGRA

- (instancetype)initWithBGRATexture:(LTTexture *)bgraTexture {
  LTParameterAssert(bgraTexture, @"BGRA texture can't be nil");
  LTParameterAssert(bgraTexture.pixelFormat.value == LTGLPixelFormatRGBA8Unorm,
      @"BGRA texture must be RGBA8Unorm");
  if (self = [super init]) {
    _bgraTexture = bgraTexture;
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
  return [NSString stringWithFormat:@"<%@: %p, bgraTexture: %@>", [self class], self,
          self.bgraTexture];
}

- (BOOL)isEqual:(CAMVideoFrameBGRA *)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[self class]]) {
    return NO;
  }

  return [self.bgraTexture isEqual:other.bgraTexture];
}

- (NSUInteger)hash {
  return self.bgraTexture.hash;
}

@end

NS_ASSUME_NONNULL_END
