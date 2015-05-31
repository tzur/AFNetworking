// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImage+Texture.h"

#import "LTTexture+Factory.h"

@interface LTImage ()
+ (void)loadImage:(UIImage *)image toMat:(cv::Mat *)mat;
+ (int)matTypeForImage:(UIImage *)image;
+ (CGSize)imageSizeInPixels:(UIImage *)image;
@end

@implementation LTImage (Texture)

+ (LTTexture *)textureWithImage:(UIImage *)image {
  LTParameterAssert(image, @"Given image cannot be nil");

  int type = [self matTypeForImage:image];

  CGSize size = [self imageSizeInPixels:image];
  LTTexture *texture = [LTTexture textureWithSize:size
                                        precision:LTTexturePrecisionFromMatType(type)
                                           format:LTTextureFormatFromMatType(type)
                                   allocateMemory:YES];

  [self loadImage:image toTexture:texture];

  return texture;
}

+ (void)loadImage:(UIImage *)image toTexture:(LTTexture *)texture {
  [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    [self loadImage:image toMat:mapped];
  }];
}

@end
