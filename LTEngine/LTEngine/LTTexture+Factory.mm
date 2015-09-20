// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture+Factory.h"

#import "LTGLContext.h"
#import "LTGLTexture.h"
#import "LTMMTexture.h"

NS_ASSUME_NONNULL_BEGIN

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
      return [LTGLContext currentContext].canRenderToHalfFloatTextures;
    case LTTexturePrecisionFloat:
      return [LTGLContext currentContext].canRenderToFloatTextures;
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

+ (instancetype)textureWithUIImage:(UIImage *)image {
  return [LTImage textureWithImage:image];
}

+ (instancetype)byteRGBATextureWithSize:(CGSize)size {
  return [[[self textureClass] alloc] initByteRGBAWithSize:size];
}

+ (instancetype)byteRedTextureWithSize:(CGSize)size {
    return [[[self textureClass] alloc] initWithSize:size precision:LTTexturePrecisionByte
                                              format:LTTextureFormatRed allocateMemory:YES];
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

NS_ASSUME_NONNULL_END
