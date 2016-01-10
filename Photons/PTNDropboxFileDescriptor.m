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

@end

@implementation PTNDropboxFileDescriptor

- (instancetype)initWithMetadata:(DBMetadata *)metadata {
  LTParameterAssert(!metadata.isDirectory, @"Given metadata does not represent a file: %@",
                    metadata);
  if (self = [super init]) {
    self.path = metadata.path;
    self.revision = metadata.rev;
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

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, path: %@, revision: %@>",
          self.class, self, self.path, self.revision ?: @"latest"];
}

- (BOOL)isEqual:(PTNDropboxFileDescriptor *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.path isEqual:object.path] &&
         (self.revision == object.revision || [self.revision isEqual:object.revision]);
}

- (NSUInteger)hash {
  return self.path.hash ^ self.revision.hash;
}

@end

NS_ASSUME_NONNULL_END
