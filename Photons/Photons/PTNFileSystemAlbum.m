// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNFileSystemAlbum.h"

#import "NSURL+FileSystem.h"
#import "PTNCollection.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNFileSystemAlbum ()

/// URL uniquely identifying this album.
@property (strong, nonatomic) NSURL *url;

/// Array of \c NSURL objects pointing to subdirectories.
@property (strong, nonatomic) PTNFileSystemSubdirectories *subdirectories;

/// Array of \c NSURL objects pointing to files.
@property (strong, nonatomic) PTNFileSystemFiles *files;

@end

@implementation PTNFileSystemAlbum

- (instancetype)initWithPath:(NSURL *)path
              subdirectories:(PTNFileSystemSubdirectories *)subdirectories
                       files:(PTNFileSystemFiles *)files {
  LTParameterAssert(path.ptn_fileSystemURLType == PTNFileSystemURLTypeAlbum, @"Invalid URL given: "
                    "%@", path);
  if (self = [super init]) {
    self.url = path;
    self.subdirectories = subdirectories;
    self.files = files;
  }
  return self;
}

- (id<PTNCollection>)assets {
  return self.files;
}

- (id<PTNCollection>)subalbums {
  return self.subdirectories;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNFileSystemAlbum *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.files isEqual:object.files] && [self.subdirectories isEqual:object.subdirectories];
}

- (NSUInteger)hash {
  return self.files.hash ^ self.subdirectories.hash;
}

@end

NS_ASSUME_NONNULL_END
