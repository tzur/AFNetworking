// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureUncompressedMatArchiver.h"

#import <LTKit/NSError+LTKit.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTTextureUncompressedMatArchiver

- (BOOL)archiveTexture:(LTTexture *)texture inPath:(NSString *)path
                 error:(NSError *__autoreleasing *)error {
  LTParameterAssert(texture);
  LTParameterAssert(path);

  __block BOOL success;
  [texture mappedImageForReading:^(const cv::Mat &mat, BOOL) {
    NSData *data;
    NSUInteger matSize = mat.total() * mat.elemSize();
    if (mat.isContinuous()) {
      data = [NSData dataWithBytesNoCopy:mat.data length:matSize freeWhenDone:NO];
    } else {
      NSMutableData *mutableData = [NSMutableData dataWithLength:matSize];
      cv::Mat continuousMat(mat.rows, mat.cols, mat.type(), mutableData.mutableBytes);
      mat.copyTo(continuousMat);
      data = mutableData;
    }

    NSError *writeError;
    NSFileManager *fileManager = [JSObjection defaultInjector][[NSFileManager class]];
    if (![fileManager lt_writeData:data toFile:path
                           options:NSDataWritingAtomic error:&writeError]) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeFileWriteFailed underlyingError:writeError];
      }
      success = NO;
    } else {
      success = YES;
    }
  }];

  return success;
}

- (BOOL)unarchiveToTexture:(LTTexture *)texture fromPath:(NSString *)path
                     error:(NSError *__autoreleasing *)error {
  LTParameterAssert(texture);

  __block BOOL success;
  [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    success = [self unarchiveToMat:mapped fromPath:path error:error];
  }];

  return success;
}

- (BOOL)unarchiveToMat:(cv::Mat *)mat fromPath:(NSString *)path
                 error:(NSError *__autoreleasing *)error {
  LTParameterAssert(mat);
  LTParameterAssert(path);

  NSError *dataError;
  NSFileManager *fileManager = [JSObjection defaultInjector][[NSFileManager class]];
  NSData *data = [fileManager lt_dataWithContentsOfFile:path
                                                options:NSDataReadingUncached error:&dataError];
  if (!data) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:path
                         underlyingError:dataError];
    }
    return NO;
  }

  LTParameterAssert(data.length == mat->total() * mat->elemSize(),
                    @"Length (%lu) of data read does not match size (%lu) of target mat",
                    (unsigned long)data.length, (unsigned long)(mat->total() * mat->elemSize()));
  cv::Mat dataMat(mat->rows, mat->cols, mat->type(), (void *)data.bytes);
  dataMat.copyTo(*mat);

  return YES;
}

@end

NS_ASSUME_NONNULL_END
