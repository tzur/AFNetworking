// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTextureContentsDataArchiver.h"

#import "NSError+LTKit.h"
#import "LTImage.h"
#import "LTTexture.h"

@implementation LTTextureContentsDataArchiver

#pragma mark -
#pragma mark NSCoding
#pragma mark -

- (id)initWithCoder:(NSCoder __unused *)aDecoder {
  return [super init];
}

- (void)encodeWithCoder:(NSCoder __unused *)aCoder {
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

#pragma mark -
#pragma mark Archiving
#pragma mark -

- (NSData *)archiveTexture:(LTTexture *)texture error:(NSError *__autoreleasing __unused *)error {
  __block NSData *data;

  [texture mappedImageForReading:^(const cv::Mat &mapped, BOOL) {
    LTImage *image = [[LTImage alloc] initWithMat:mapped copy:NO];
    data = UIImagePNGRepresentation([image UIImage]);
  }];

  return data;
}

- (BOOL)unarchiveData:(NSData *)data toTexture:(LTTexture *)texture
                error:(NSError *__autoreleasing *)error {
  UIImage *image = [UIImage imageWithData:data];
  if (!image) {
    if (error) {
      *error = [NSError errorWithDomain:kLTKitErrorDomain code:NSFileReadCorruptFileError
                               userInfo:nil];
    }
    return NO;
  }

  LTImage *ltImage = [[LTImage alloc] initWithImage:image];
  [texture load:ltImage.mat];

  return YES;
}

@end
