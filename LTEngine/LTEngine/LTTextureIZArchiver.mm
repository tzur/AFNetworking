// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureIZArchiver.h"

#import <LTKit/NSError+LTKit.h>

#import "LTIZCompressor.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTTextureIZArchiver ()

/// ImageZero compressor used to compress and decompress images.
@property (strong, nonatomic) LTIZCompressor *compressor;

@end

@implementation LTTextureIZArchiver

- (instancetype)init {
  if (self = [super init]) {
    self.compressor = [JSObjection defaultInjector][[LTIZCompressor class]];
  }
  return self;
}

- (BOOL)archiveTexture:(LTTexture *)texture inPath:(NSString *)path
                 error:(NSError *__autoreleasing *)error {
  LTParameterAssert(path);
  [self verifyTexture:texture];

  __block BOOL success;
  [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    success = [self.compressor compressImage:mapped toPath:path error:error withAlpha:NO];
  }];
  
  return success;
}

- (BOOL)unarchiveToTexture:(LTTexture *)texture fromPath:(NSString *)path
                     error:(NSError *__autoreleasing *)error {
  LTParameterAssert(path);
  [self verifyTexture:texture];

  __block BOOL success;
  [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    success = [self.compressor decompressFromPath:path toImage:mapped error:error];
  }];

  return success;
}

- (BOOL)unarchiveToMat:(cv::Mat *)mat fromPath:(NSString *)path
                 error:(NSError *__autoreleasing *)error {
  LTParameterAssert(mat);
  LTParameterAssert(path);
  LTParameterAssert(mat->type() == CV_8UC1 || mat->type() == CV_8UC4,
                    @"ImageZero compression supports only byte precision R or RGBA images: %d",
                    mat->type());
  return [self.compressor decompressFromPath:path toImage:mat error:error];
}

- (void)verifyTexture:(LTTexture *)texture {
  LTParameterAssert(texture);
  LTParameterAssert(texture.pixelFormat.value == LTGLPixelFormatR8Unorm ||
                    texture.pixelFormat.value == LTGLPixelFormatRGBA8Unorm,
                    @"ImageZero compression supports only byte precision R or RGBA textures: %@",
                    texture.pixelFormat.name);
  LTParameterAssert(!texture.usingAlphaChannel);
}

@end

NS_ASSUME_NONNULL_END
