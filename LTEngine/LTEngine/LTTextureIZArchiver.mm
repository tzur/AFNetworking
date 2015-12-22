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
    success = [self.compressor decompressFromPath:path toImage:(cv::Mat4b *)mapped error:error];
  }];

  return success;
}

- (void)verifyTexture:(LTTexture *)texture {
  LTParameterAssert(texture);
  LTParameterAssert(texture.pixelFormat.value == LTGLPixelFormatR8Unorm ||
                    texture.pixelFormat.value == LTGLPixelFormatRGBA8Unorm);
  LTParameterAssert(!texture.usingAlphaChannel);
}

- (BOOL)removeArchiveInPath:(NSString *)path error:(NSError *__autoreleasing *)error {
  NSFileManager *fileManager = [JSObjection defaultInjector][[NSFileManager class]];

  NSArray *paths = [self.compressor shardsPathsOfCompressedImageFromPath:path error:error];
  if (!paths) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileRemovalFailed
                         underlyingError:*error];
    }
    return NO;
  }

  BOOL failed = NO;
  NSMutableArray *underlyingErrors = [NSMutableArray array];

  for (NSString *path in paths) {
    NSError *removalError;
    if (![fileManager removeItemAtPath:path error:&removalError]) {
      if (removalError) {
        [underlyingErrors addObject:removalError];
      }
      failed = YES;
    }
  }

  if (failed) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileRemovalFailed
                        underlyingErrors:[underlyingErrors copy]];
    }
    return NO;
  }

  return YES;
}

@end

NS_ASSUME_NONNULL_END
