// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "LTTextureOpenExrArchiver.h"

#import <LTKit/NSError+LTKit.h>

#import "LTOpenCVHalfFloat.h"
#import "LTOpenExrPizCompressor.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTTextureOpenExrArchiver ()

/// OpenEXR PIZ compressor used to compress and decompress images.
@property (readonly, nonatomic) LTOpenExrPizCompressor *compressor;

@end

@implementation LTTextureOpenExrArchiver

- (instancetype)init {
  if (self = [super init]) {
    _compressor = [[LTOpenExrPizCompressor alloc] init];
  }
  return self;
}

- (BOOL)archiveTexture:(LTTexture *)texture inPath:(NSString *)path
                 error:(NSError *__autoreleasing *)error {
  LTParameterAssert(path);
  [self verifyTexture:texture];

  __block BOOL success;
  [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    success = [self.compressor compressImage:mapped toPath:path error:error];
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
  LTParameterAssert(mat->type() == CV_16FC4,
                    @"OpenEXR PIZ compression supports only half-float precision RGBA images, got "
                    "type: %d", mat->type());
  return [self.compressor decompressFromPath:path toImage:mat error:error];
}

- (void)verifyTexture:(LTTexture *)texture {
  LTParameterAssert(texture);
  LTParameterAssert(texture.pixelFormat.value == LTGLPixelFormatRGBA16Float,
                    @"OpenEXR PIZ compression supports only half-float precision RGBA images, got "
                    "format: %@", texture.pixelFormat.name);
}

@end

NS_ASSUME_NONNULL_END
