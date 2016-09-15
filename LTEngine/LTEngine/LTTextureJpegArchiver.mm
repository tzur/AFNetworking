// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureJpegArchiver.h"

#import <LTKit/LTImageLoader.h>
#import <LTKit/NSError+LTKit.h>

#import "LTImage.h"
#import "LTImage+Texture.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTTextureJpegArchiver

- (BOOL)archiveTexture:(LTTexture *)texture inPath:(NSString *)path
                 error:(NSError *__autoreleasing *)error {
  LTParameterAssert(path);
  [self verifyTexture:texture];

  __block BOOL success;
  [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    LTImage *image = [[LTImage alloc] initWithMat:mapped copy:NO];
    success = [image writeToPath:path error:error];
  }];
  
  return success;
}

- (BOOL)unarchiveToTexture:(LTTexture *)texture fromPath:(NSString *)path
                     error:(NSError *__autoreleasing *)error {
  LTParameterAssert(path);
  [self verifyTexture:texture];

  UIImage * _Nullable image = [self unarchiveImageFromPath:path error:error];
  if (!image) {
    return NO;
  }

  [LTImage loadImage:image toTexture:texture];
  return YES;
}

- (BOOL)unarchiveToMat:(cv::Mat *)mat fromPath:(NSString *)path
                 error:(NSError *__autoreleasing *)error {
  LTParameterAssert(mat);
  LTParameterAssert(path);
  LTParameterAssert(mat->depth() == 8, @"JPEG compression supports only byte precision images: %d",
                    mat->depth());

  UIImage *uiImage = [self unarchiveImageFromPath:path error:error];
  if (!uiImage) {
    return NO;
  }

  LTImage *ltImage = [[LTImage alloc] initWithImage:uiImage];
  ltImage.mat.copyTo(*mat);
  return YES;
}

- (nullable UIImage *)unarchiveImageFromPath:(NSString *)path
                                       error:(NSError *__autoreleasing *)error {
  LTParameterAssert(path);
  LTImageLoader *imageLoader = [JSObjection defaultInjector][[LTImageLoader class]];
  UIImage * _Nullable image = [imageLoader imageWithContentsOfFile:path];
  if (!image && error) {
    *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:path];
  }

  return image;
}

- (void)verifyTexture:(LTTexture *)texture {
  LTParameterAssert(texture);
  LTParameterAssert(texture.bitDepth == LTGLPixelBitDepth8,
                    @"JPEG compression supports only byte precision textures: %lu",
                    (unsigned long)texture.bitDepth);
  LTParameterAssert(!texture.usingAlphaChannel,
                    @"JPEG compression does not support textures using their alpha channel");
}

@end

NS_ASSUME_NONNULL_END
