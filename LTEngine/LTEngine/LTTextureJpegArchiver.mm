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

  LTImageLoader *imageLoader = [JSObjection defaultInjector][[LTImageLoader class]];
  UIImage *image = [imageLoader imageWithContentsOfFile:path];
  if (!image) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:path];
    }
    return NO;
  }

  [LTImage loadImage:image toTexture:texture];
  return YES;
}

- (void)verifyTexture:(LTTexture *)texture {
  LTParameterAssert(texture);
  LTParameterAssert(texture.bitDepth == LTGLPixelBitDepth8);
  LTParameterAssert(!texture.usingAlphaChannel);
}

- (BOOL)removeArchiveInPath:(NSString *)path error:(NSError *__autoreleasing *)error {
  NSFileManager *fileManager = [JSObjection defaultInjector][[NSFileManager class]];
  NSError *removalError;
  if (![fileManager removeItemAtPath:path error:&removalError]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileRemovalFailed path:path
                         underlyingError:removalError];
    }
    return NO;
  }
  return YES;
}

@end

NS_ASSUME_NONNULL_END
