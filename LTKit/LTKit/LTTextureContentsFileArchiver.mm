// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureContentsFileArchiver.h"

#import "LTImage.h"
#import "LTFileManager.h"
#import "LTTexture.h"

@interface LTTextureContentsFileArchiver ()
@property (strong, nonatomic) NSString *filePath;
@end

@implementation LTTextureContentsFileArchiver

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return [self initWithFilePath:[self temporaryFilePath]];
}

- (instancetype)initWithFilePath:(NSString *)filePath {
  if (self = [super init]) {
    self.filePath = filePath;
    self.fileManager = [JSObjection defaultInjector][[LTFileManager class]];
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
  [self verifySupportedTexture:texture];

  __block NSData *png;
  [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    LTImage *image = [[LTImage alloc] initWithMat:mapped copy:NO];
    png = UIImagePNGRepresentation([image UIImage]);
  }];

  if (![self.fileManager writeData:png toFile:self.filePath options:NSDataWritingAtomic
                            error:error]) {
    return nil;
  }
  return [NSData data];
}

- (BOOL)unarchiveData:(NSData *)data toTexture:(LTTexture *)texture
                error:(NSError *__autoreleasing *)error {
  LTParameterAssert(data && !data.length, @"Given data must be an empty NSData object");

  [self verifySupportedTexture:texture];

  NSData *png = [self.fileManager dataWithContentsOfFile:self.filePath options:0 error:error];
  if (!png) {
    return NO;
  }

  UIImage *image = [UIImage imageWithData:png];
  if (!image) {
    if (error) {
      *error = [NSError errorWithDomain:kLTKitErrorDomain code:NSFileReadCorruptFileError
                               userInfo:@{NSFilePathErrorKey: self.filePath}];
    }
    return NO;
  }

  // Keep memory footprint low.
  png = nil;
  LTImage *ltImage = [[LTImage alloc] initWithImage:image];
  image = nil;

  [texture load:ltImage.mat];

  return YES;
}

- (void)verifySupportedTexture:(LTTexture *)texture {
  LTParameterAssert(texture.precision == LTTexturePrecisionByte &&
                    texture.format == LTTextureFormatRGBA, @"Only RGBA8 textures are supported");
}

@end

@implementation LTTextureContentsFileArchiver (ForTesting)

- (LTFileManager *)fileManager {
  return objc_getAssociatedObject(self, @selector(fileManager));
}

- (void)setFileManager:(LTFileManager *)fileManager {
  objc_setAssociatedObject(self, @selector(fileManager), fileManager,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
