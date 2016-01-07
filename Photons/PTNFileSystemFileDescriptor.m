// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNFileSystemFileDescriptor.h"

#import <LTKit/LTPath.h>

#import "NSURL+FileSystem.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTNFileSystemFileDescriptor ()

/// Path of the descriptor.
@property (strong, nonatomic) LTPath *path;

@end

@implementation PTNFileSystemFileDescriptor

- (instancetype)initWithPath:(LTPath *)path {
  if (self = [super init]) {
    self.path = path;
  }
  return self;
}

- (NSURL *)ptn_identifier {
  return [NSURL ptn_fileSystemAssetURLWithPath:self.path];
}

- (nullable NSString *)localizedTitle {
  return self.path.relativePath.lastPathComponent;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, path: %@>", self.class, self, self.path];
}

- (BOOL)isEqual:(PTNFileSystemFileDescriptor *)object {
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
