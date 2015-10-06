// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureContentsFileArchiver.h"

#import <LTKit/LTImageLoader.h>
#import <LTKit/NSError+LTKit.h>
#import <LTKit/NSFileManager+LTKit.h>

#import "LTImage.h"
#import "LTImage+Texture.h"
#import "LTTexture.h"

@interface LTTextureContentsFileArchiver ()

@property (strong, nonatomic) NSString *filePath;

@end

@implementation LTTextureContentsFileArchiver

objection_initializer_sel(@selector(initWithFilePath:));

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return [self initWithFilePath:[self temporaryFilePath]];
}

- (instancetype)initWithFilePath:(NSString *)filePath {
  if (self = [super init]) {
    self.filePath = filePath;
  }
  return self;
}

- (NSString *)temporaryFilePath {
  NSString *uuid = [[[NSUUID alloc] init] UUIDString];
  NSString *fileName = [uuid stringByAppendingPathExtension:@"texture"];
  return [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
}

#pragma mark -
#pragma mark NSCoding
#pragma mark -

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super init]) {
    self.filePath = [aDecoder decodeObjectOfClass:[NSString class] forKey:@keypath(self, filePath)];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.filePath forKey:@keypath(self, filePath)];
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

#pragma mark -
#pragma mark Archiving
#pragma mark -

- (NSData *)archiveTexture:(LTTexture *)texture error:(NSError *__autoreleasing *)error {
  __block BOOL stored;

  [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    if (texture.precision == LTTexturePrecisionByte) {
      stored = [self archiveBytePrecisionMat:mapped error:error];
    } else {
      stored = [self archiveNonBytePrecisionMat:mapped error:error];
    }
  }];

  if (!stored) {
    return nil;
  }
  return [NSData data];
}

- (BOOL)archiveBytePrecisionMat:(const cv::Mat &)mat error:(NSError *__autoreleasing *)error {
  LTImage *image = [[LTImage alloc] initWithMat:mat copy:NO];
  return [image writeToPath:self.filePath error:error];
}

- (BOOL)archiveNonBytePrecisionMat:(const cv::Mat &)mat error:(NSError *__autoreleasing *)error {
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

  NSFileManager *fileManager = [JSObjection defaultInjector][[NSFileManager class]];
  return [fileManager lt_writeData:data toFile:self.filePath
                           options:NSDataWritingAtomic error:error];
}

- (BOOL)unarchiveData:(NSData *)data toTexture:(LTTexture *)texture
                error:(NSError *__autoreleasing *)error {
  LTParameterAssert(data && !data.length, @"Given data must be an empty NSData object");

  BOOL success;
  if (texture.precision == LTTexturePrecisionByte) {
    success = [self unarchiveToByteTexture:texture error:error];
  } else {
    success = [self unarchiveToNonByteTexture:texture error:error];
  }

  if (success && error) {
    *error = nil;
  }
  return success;
}

- (BOOL)unarchiveToByteTexture:(LTTexture *)texture error:(NSError *__autoreleasing *)error {
  LTImageLoader *imageLoader = [JSObjection defaultInjector][[LTImageLoader class]];
  UIImage *image = [imageLoader imageWithContentsOfFile:self.filePath];
  if (!image) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:self.filePath];
    }
    return NO;
  }

  [LTImage loadImage:image toTexture:texture];
  return YES;
}

- (BOOL)unarchiveToNonByteTexture:(LTTexture *)texture error:(NSError *__autoreleasing *)error {
  NSFileManager *fileManager = [JSObjection defaultInjector][[NSFileManager class]];
  NSData *data = [fileManager lt_dataWithContentsOfFile:self.filePath
                                                options:NSDataReadingUncached error:error];
  if (!data) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed path:self.filePath];
    }
    return NO;
  }

  [texture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    LTParameterAssert(data.length == mapped->total() * mapped->elemSize());
    cv::Mat mat(mapped->rows, mapped->cols, mapped->type(), (void *)data.bytes);
    mat.copyTo(*mapped);
  }];
  return YES;
}

@end
