// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImage+Texture.h"

#import "LTTexture+Factory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTImage ()
+ (void)loadImage:(UIImage *)image toMat:(cv::Mat *)mat
  backgroundColor:(nullable UIColor *)backgroundColor;
+ (int)matTypeForImage:(UIImage *)image;
+ (CGSize)imageSizeInPixels:(UIImage *)image;
@end

@implementation LTImage (Texture)

+ (LTTexture *)textureWithImage:(UIImage *)image {
  return [self textureWithImage:image backgroundColor:nil];
}

+ (LTTexture *)textureWithImage:(UIImage *)image
                backgroundColor:(nullable UIColor *)backgroundColor {
  LTParameterAssert(image, @"Given image cannot be nil");

  int type = [self matTypeForImage:image];
  LTGLPixelFormat *pixelFormat = [[LTGLPixelFormat alloc] initWithMatType:type];

  CGSize size = [self imageSizeInPixels:image];
  LTTexture *texture = [LTTexture textureWithSize:size pixelFormat:pixelFormat allocateMemory:YES];

  [self loadImage:image toTexture:texture backgroundColor:backgroundColor];

  return texture;
}

+ (void)loadImage:(UIImage *)image toTexture:(LTTexture *)texture {
  return [self loadImage:image toTexture:texture backgroundColor:nil];
}

+ (void)loadImage:(UIImage *)image toTexture:(LTTexture *)texture
  backgroundColor:(nullable UIColor *)backgroundColor {
  [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    [self loadImage:image toMat:mapped backgroundColor:backgroundColor];
  }];
}

@end

NS_ASSUME_NONNULL_END
