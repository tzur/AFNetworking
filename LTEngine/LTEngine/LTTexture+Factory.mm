// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture+Factory.h"

#import "LTCVPixelBufferExtensions.h"
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
#if TARGET_OS_SIMULATOR
    activeClass = [LTGLTexture class];
#elif !TARGET_OS_SIMULATOR && TARGET_OS_IPHONE
    activeClass = [LTMMTexture class];
#endif
  });

  return activeClass;
}

+ (Class)defaultTextureClass {
  return [LTGLTexture class];
}

+ (BOOL)isMemoryMappedTextureAvailable {
  return [self textureClass] == [LTMMTexture class];
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
  return [LTImage textureWithImage:image backgroundColor:nil];
}

+ (instancetype)textureWithUIImage:(UIImage *)image backgroundColor:(UIColor *)backgroundColor {
  return [LTImage textureWithImage:image backgroundColor:backgroundColor];
}

+ (instancetype)byteRGBATextureWithSize:(CGSize)size {
  return [self textureWithSize:size pixelFormat:$(LTGLPixelFormatRGBA8Unorm) maxMipmapLevel:0
                allocateMemory:YES];
}

+ (instancetype)byteRedTextureWithSize:(CGSize)size {
  return [self textureWithSize:size pixelFormat:$(LTGLPixelFormatR8Unorm) maxMipmapLevel:0
                allocateMemory:YES];
}

+ (instancetype)halfFloatRGBATextureWithSize:(CGSize)size {
  return [self textureWithSize:size pixelFormat:$(LTGLPixelFormatRGBA16Float) maxMipmapLevel:0
                allocateMemory:YES];
}

+ (instancetype)halfFloatRedTextureWithSize:(CGSize)size {
  return [self textureWithSize:size pixelFormat:$(LTGLPixelFormatR16Float) maxMipmapLevel:0
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

+ (instancetype)textureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
  if ([self isMemoryMappedTextureAvailable]) {
    return [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer];
  } else {
    __block LTTexture *texture;
    LTCVPixelBufferImageForReading(pixelBuffer, ^(const cv::Mat &image) {
      texture = [self textureWithImage:image];
    });
    return texture;
  }
}

+ (instancetype)textureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer planeIndex:(size_t)planeIndex {
  if ([self isMemoryMappedTextureAvailable]) {
    return [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer planeIndex:planeIndex];
  } else {
    __block LTTexture *texture;
    LTCVPixelBufferPlaneImageForReading(pixelBuffer, planeIndex, ^(const cv::Mat &image) {
      texture = [self textureWithImage:image];
    });
    return texture;
  }
}

@end

NS_ASSUME_NONNULL_END
