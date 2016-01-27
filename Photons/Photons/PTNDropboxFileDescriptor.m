// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxFileDescriptor.h"

#import <DropboxSDK/DropboxSDK.h>

#import "NSURL+Dropbox.h"
#import "PTNDropboxEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNDropboxFileDescriptor ()

/// Path associated with this descriptor.
@property (strong, nonatomic) NSString *path;

/// Revision associated with this descriptor.
@property (strong, nonatomic) NSString *revision;

/// Date the Dropbox entry represented by this descriptor was last modified.
@property (strong, nonatomic, nullable) NSDate *modificationDate;

@end

@implementation PTNDropboxFileDescriptor

- (instancetype)initWithMetadata:(DBMetadata *)metadata {
  LTParameterAssert(!metadata.isDirectory, @"Given metadata does not represent a file: %@",
                    metadata);
  if (self = [super init]) {
    self.path = metadata.path;
    self.revision = metadata.rev;
    self.modificationDate = metadata.lastModifiedDate;
  }
  return self;
}

- (NSURL *)ptn_identifier {
  PTNDropboxEntry *entry = [PTNDropboxEntry entryWithPath:self.path
                                              andRevision:self.revision];
  return [NSURL ptn_dropboxAssetURLWithEntry:entry];
}

- (nullable NSString *)localizedTitle {
  return self.path.lastPathComponent;
}

- (nullable NSDate *)creationDate {
  // Unavailable in Dropbox API.
  return nil;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, path: %@, revision: %@, last modified: %@>",
          self.class, self, self.path, self.revision ?: @"latest", self.modificationDate ?: @"N/A"];
}

- (BOOL)isEqual:(PTNDropboxFileDescriptor *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.path isEqual:object.path] &&
         (self.revision == object.revision || [self.revision isEqual:object.revision]) &&
         (self.modificationDate == object.modificationDate ||
             [self.modificationDate isEqualToDate:object.modificationDate]);
}

- (NSUInteger)hash {
  return self.path.hash ^ self.revision.hash ^ self.modificationDate.hash;
}

@end

NS_ASSUME_NONNULL_END
