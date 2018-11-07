// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNFileSystemDirectoryDescriptor.h"

#import <LTKit/LTPath.h>

#import "NSURL+FileSystem.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNFileSystemDirectoryDescriptor ()

/// Path of the descriptor.
@property (strong, nonatomic) LTPath *path;

@end

@implementation PTNFileSystemDirectoryDescriptor

- (instancetype)initWithPath:(LTPath *)path {
  if (self = [super init]) {
    self.path = path;
  }
  return self;
}

- (NSURL *)ptn_identifier {
  return [NSURL ptn_fileSystemAlbumURLWithPath:self.path];
}

- (nullable NSString *)localizedTitle {
  return self.path.relativePath.lastPathComponent;
}

- (NSUInteger)assetCount {
  return PTNNotFound;
}

- (PTNDescriptorCapabilities)descriptorCapabilities {
  return PTNDescriptorCapabilityNone;
}

- (PTNAlbumDescriptorCapabilities)albumDescriptorCapabilities {
  return PTNAlbumDescriptorCapabilityNone;
}

- (NSSet<NSString *> *)descriptorTraits {
  return [NSSet set];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, path: %@>", self.class, self, self.path];
}

- (BOOL)isEqual:(PTNFileSystemDirectoryDescriptor *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.path isEqual:object.path];
}

- (NSUInteger)hash {
  return self.path.hash;
}

@end

NS_ASSUME_NONNULL_END
