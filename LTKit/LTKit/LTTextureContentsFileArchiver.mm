// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureContentsFileArchiver.h"

#import "LTImage.h"
#import "LTImage+Texture.h"
#import "LTImageLoader.h"
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

- (id)initWithCoder:(NSCoder *)aDecoder {
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
    LTImage *image = [[LTImage alloc] initWithMat:mapped copy:NO];
    stored = [image writeToPath:self.filePath error:error];
  }];

  if (!stored) {
    return nil;
  }
  return [NSData data];
}

- (BOOL)unarchiveData:(NSData *)data toTexture:(LTTexture *)texture
                error:(NSError *__autoreleasing *)error {
  LTParameterAssert(data && !data.length, @"Given data must be an empty NSData object");

  LTImageLoader *imageLoader = [JSObjection defaultInjector][[LTImageLoader class]];
  UIImage *image = [imageLoader imageWithContentsOfFile:self.filePath];
  if (!image) {
    if (error) {
      *error = [NSError errorWithDomain:kLTKitErrorDomain code:NSFileReadCorruptFileError
                               userInfo:@{NSFilePathErrorKey: self.filePath}];
    }
    return NO;
  }

  [LTImage loadImage:image toTexture:texture];

  if (error) {
    *error = nil;
  }
  return YES;
}

@end
