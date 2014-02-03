// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture+Factory.h"

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

+ (instancetype)textureWithSize:(CGSize)size precision:(LTTexturePrecision)precision
                       channels:(LTTextureChannels)channels allocateMemory:(BOOL)allocateMemory {
  return [[[self textureClass] alloc] initWithSize:size precision:precision
                                          channels:channels allocateMemory:allocateMemory];
}

+ (instancetype)textureWithImage:(const cv::Mat &)image {
  return [(LTTexture *)[[self textureClass] alloc] initWithImage:image];
}

+ (instancetype)byteRGBATextureWithSize:(CGSize)size {
  return [[[self textureClass] alloc] initByteRGBAWithSize:size];
}

+ (instancetype)textureWithPropertiesOf:(LTTexture *)texture {
  return [[[self textureClass] alloc] initWithPropertiesOf:texture];
}

+ (instancetype)textureWithBaseLevelMipmapImage:(const cv::Mat &)image {
  return [[LTGLTexture alloc] initWithBaseLevelMipmapImage:image];
}

+ (instancetype)textureWithMipmapImages:(const Matrices &)images {
  return [[LTGLTexture alloc] initWithMipmapImages:images];
}

@end
