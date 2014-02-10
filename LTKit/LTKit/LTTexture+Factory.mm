// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture+Factory.h"

#import "LTDevice.h"
#import "LTGLTexture.h"
#import "LTMMTexture.h"

@implementation LTTexture (Factory)

+ (Class)textureClass {
  static Class activeClass;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
#if TARGET_IPHONE_SIMULATOR
    activeClass = [LTGLTexture class];
#elif !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    activeClass = [LTMMTexture class];
#endif
  });

  return activeClass;
}

+ (Class)defaultTextureClass {
  return [LTGLTexture class];
}

+ (Class)classForPrecision:(LTTexturePrecision)precision {
  if ([[self class] precisionSupportedByMemoryMappedTexture:precision]) {
    return [[self class] textureClass];
  } else {
    return [[self class] defaultTextureClass];
  }
}

+ (BOOL)precisionSupportedByMemoryMappedTexture:(LTTexturePrecision)precision {
  switch (precision) {
    case LTTexturePrecisionByte:
      return YES;
    case LTTexturePrecisionHalfFloat:
      return [[LTDevice currentDevice] canRenderToHalfFloatTextures];
    case LTTexturePrecisionFloat:
      return [[LTDevice currentDevice] canRenderToFloatTextures];
  }
}

+ (instancetype)textureWithSize:(CGSize)size precision:(LTTexturePrecision)precision
                         format:(LTTextureFormat)format allocateMemory:(BOOL)allocateMemory {
  Class textureClass = [self classForPrecision:precision];
  return [[textureClass alloc] initWithSize:size precision:precision
                                     format:format allocateMemory:allocateMemory];
}

+ (instancetype)textureWithImage:(const cv::Mat &)image {
  LTTexturePrecision precision = LTTexturePrecisionFromMat(image);
  Class textureClass = [self classForPrecision:precision];
  return [(LTTexture *)[textureClass alloc] initWithImage:image];
}

+ (instancetype)byteRGBATextureWithSize:(CGSize)size {
  return [[[self textureClass] alloc] initByteRGBAWithSize:size];
}

+ (instancetype)textureWithPropertiesOf:(LTTexture *)texture {
  Class textureClass = [self classForPrecision:texture.precision];
  return [[textureClass alloc] initWithPropertiesOf:texture];
}

+ (instancetype)textureWithBaseLevelMipmapImage:(const cv::Mat &)image {
  return [[LTGLTexture alloc] initWithBaseLevelMipmapImage:image];
}

+ (instancetype)textureWithMipmapImages:(const Matrices &)images {
  return [[LTGLTexture alloc] initWithMipmapImages:images];
}

@end
