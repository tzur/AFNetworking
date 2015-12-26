// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture+Factory.h"

#import "LTGLContext.h"
#import "LTGLTexture.h"
#import "LTImage+Texture.h"
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

+ (Class)classForPixelFormat:(LTGLPixelFormat *)pixelFormat {
  if ([[self class] pixelFormatSupportedByMemoryMappedTexture:pixelFormat]) {
    return [[self class] textureClass];
  } else {
    return [[self class] defaultTextureClass];
  }
}

+ (BOOL)pixelFormatSupportedByMemoryMappedTexture:(LTGLPixelFormat *)pixelFormat {
  if (pixelFormat.bitDepth == LTGLPixelBitDepth8 &&
      pixelFormat.dataType == LTGLPixelDataTypeUnorm) {
    return YES;
  } else if (pixelFormat.bitDepth == LTGLPixelBitDepth16 &&
             pixelFormat.dataType == LTGLPixelDataTypeFloat) {
    return [LTGLContext currentContext].canRenderToHalfFloatTextures;
  } else if (pixelFormat.bitDepth == LTGLPixelBitDepth32 &&
             pixelFormat.dataType == LTGLPixelDataTypeFloat) {
    return [LTGLContext currentContext].canRenderToFloatTextures;
  } else {
    // Unknown pixel format, assume that LTMMTexture cannot handle it.
    return NO;
  }
}

+ (instancetype)textureWithSize:(CGSize)size pixelFormat:(LTGLPixelFormat *)pixelFormat
                 allocateMemory:(BOOL)allocateMemory {
  Class textureClass = [self classForPixelFormat:pixelFormat];
  return [[textureClass alloc] initWithSize:size pixelFormat:pixelFormat
                             allocateMemory:allocateMemory];
}

+ (instancetype)textureWithImage:(const cv::Mat &)image {
  LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc] initWithMatType:image.type()];
  Class textureClass = [self classForPixelFormat:pixelFormat];
  return [(LTTexture *)[textureClass alloc] initWithImage:image];
}

+ (instancetype)textureWithUIImage:(UIImage *)image {
  return [LTImage textureWithImage:image];
}

+ (instancetype)byteRGBATextureWithSize:(CGSize)size {
  return [[[self textureClass] alloc] initWithSize:size
                                       pixelFormat:$(LTGLPixelFormatRGBA8Unorm)
                                    allocateMemory:YES];
}

+ (instancetype)byteRedTextureWithSize:(CGSize)size {
  return [[[self textureClass] alloc] initWithSize:size
                                       pixelFormat:$(LTGLPixelFormatR8Unorm)
                                    allocateMemory:YES];
}

+ (instancetype)textureWithPropertiesOf:(LTTexture *)texture {
  Class textureClass = [self classForPixelFormat:texture.pixelFormat];
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
