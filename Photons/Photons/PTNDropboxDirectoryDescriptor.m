// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxDirectoryDescriptor.h"

#import <DropboxSDK/DropboxSDK.h>

#import "NSURL+Dropbox.h"
#import "PTNDropboxEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNDropboxDirectoryDescriptor ()

/// Path associated with this descriptor.
@property (strong, nonatomic) NSString *path;

/// Estimated asset count associated with this descriptor.
@property (nonatomic) NSUInteger assetCount;

@end

@implementation PTNDropboxDirectoryDescriptor

- (instancetype)initWithMetadata:(DBMetadata *)metadata {
  LTParameterAssert(metadata.isDirectory, @"Given metadata does not represent a directory: %@",
                    metadata);
  if (self = [super init]) {
    self.path = metadata.path;
    self.assetCount = [self estimateAssetCount:metadata];
  }
  return self;
}

- (NSUInteger)estimateAssetCount:(DBMetadata *)metadata {
  if (!metadata.contents) {
    return PTNNotFound;
  }
  return [metadata.contents.rac_sequence filter:^BOOL(DBMetadata * content) {
    return !content.isDirectory;
  }].array.count;
}

- (NSURL *)ptn_identifier {
  PTNDropboxEntry *entry = [PTNDropboxEntry entryWithPath:self.path];
  return [NSURL ptn_dropboxAlbumURLWithEntry:entry];
}

- (nullable NSString *)localizedTitle {
  return self.path.lastPathComponent;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, path: %@, assetCount: %lu>",
          self.class, self, self.path, (unsigned long)self.assetCount];
}

- (BOOL)isEqual:(PTNDropboxDirectoryDescriptor *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.path isEqual:object.path] &&
         self.assetCount == object.assetCount;
}

- (NSUInteger)hash {
  return self.path.hash ^ self.assetCount;
}

@end

NS_ASSUME_NONNULL_END
