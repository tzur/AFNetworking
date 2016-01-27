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

+ (Class)classForPixelFormat:(LTGLPixelFormat *)pixelFormat maxMipmapLevel:(GLint)maxMipmapLevel {
  // LTGLTexture is the only implementation supporting mipmaps. When the latter is required, memory
  // mapped textures cannot be used.
  if (!maxMipmapLevel && [self pixelFormatSupportedByMemoryMappedTexture:pixelFormat]) {
    return [self textureClass];
  } else {
    return [self defaultTextureClass];
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
                 maxMipmapLevel:(GLint)maxMipmapLevel
                 allocateMemory:(BOOL)allocateMemory {
  Class textureClass = [self classForPixelFormat:pixelFormat maxMipmapLevel:maxMipmapLevel];
  return [[textureClass alloc] initWithSize:size pixelFormat:pixelFormat
                             maxMipmapLevel:maxMipmapLevel
                             allocateMemory:allocateMemory];
}

+ (instancetype)textureWithSize:(CGSize)size pixelFormat:(LTGLPixelFormat *)pixelFormat
                 allocateMemory:(BOOL)allocateMemory {
  return [self textureWithSize:size pixelFormat:pixelFormat maxMipmapLevel:0
                allocateMemory:allocateMemory];
}

+ (instancetype)textureWithImage:(const cv::Mat &)image {
  LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc] initWithMatType:image.type()];
  Class textureClass = [self classForPixelFormat:pixelFormat maxMipmapLevel:0];
  return [(LTTexture *)[textureClass alloc] initWithImage:image];
}

+ (instancetype)textureWithUIImage:(UIImage *)image {
  return [LTImage textureWithImage:image];
}

+ (instancetype)byteRGBATextureWithSize:(CGSize)size {
  return [self textureWithSize:size pixelFormat:$(LTGLPixelFormatRGBA8Unorm) maxMipmapLevel:0
                allocateMemory:YES];
}

+ (instancetype)byteRedTextureWithSize:(CGSize)size {
  return [self textureWithSize:size pixelFormat:$(LTGLPixelFormatR8Unorm) maxMipmapLevel:0
                allocateMemory:YES];
}

+ (instancetype)textureWithPropertiesOf:(LTTexture *)texture {
  return [self textureWithSize:texture.size pixelFormat:texture.pixelFormat
                maxMipmapLevel:texture.maxMipmapLevel
                allocateMemory:YES];
}

+ (instancetype)textureWithBaseLevelMipmapImage:(const cv::Mat &)image {
  return [[LTGLTexture alloc] initWithBaseLevelMipmapImage:image];
}

+ (instancetype)textureWithMipmapImages:(const Matrices &)images {
  return [[LTGLTexture alloc] initWithMipmapImages:images];
}

@end

NS_ASSUME_NONNULL_END
