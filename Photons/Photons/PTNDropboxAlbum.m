// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxAlbum.h"

#import "NSURL+Dropbox.h"
#import "PTNCollection.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNDropboxAlbum ()

/// URL uniquely identifying this album.
@property (strong, nonatomic) NSURL *url;

/// Array of \c NSURL objects pointing to subdirectories.
@property (strong, nonatomic) PTNDropboxSubdirectories *subdirectories;

/// Array of \c NSURL objects pointing to files.
@property (strong, nonatomic) PTNDropboxFiles *files;

@end

@implementation PTNDropboxAlbum

- (instancetype)initWithPath:(NSURL *)path
              subdirectories:(PTNDropboxSubdirectories *)subdirectories
                       files:(PTNDropboxFiles *)files {
  LTParameterAssert(path.ptn_dropboxURLType == PTNDropboxURLTypeAlbum, @"Invalid URL given: %@",
                    path);
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

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, path: %@, subalbums: %@, assets: %@>",
          self.class, self, self.url, self.subdirectories, self.files];
}

- (BOOL)isEqual:(PTNDropboxAlbum *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.url isEqual:object.url] &&
         [self.files isEqual:object.files] &&
         [self.subdirectories isEqual:object.subdirectories];
}

- (NSUInteger)hash {
  return self.url.hash ^ self.files.hash ^ self.subdirectories.hash;
}

@end

NS_ASSUME_NONNULL_END
