// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxEntry.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNDropboxEntry

- (instancetype)initWithPath:(NSString *)path
                    revision:(nullable NSString *)revision {
  if (self = [super init]) {
    _path = path;
    _revision = revision;
  }
  return self;
}

+ (PTNDropboxEntry *)entryWithPath:(NSString *)path andRevision:(nullable NSString *)revision {
  return [[PTNDropboxEntry alloc] initWithPath:path revision:revision];
}

+ (PTNDropboxEntry *)entryWithPath:(NSString *)path {
  return [[PTNDropboxEntry alloc] initWithPath:path revision:nil];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, path: %@, revision: %@>", self.class, self,
          self.path, self.revision ?: @"latest"];
}

- (BOOL)isEqual:(PTNDropboxEntry *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self.path isEqualToString:object.path] &&
         (self.revision == object.revision || [self.revision isEqualToString:object.revision]);
}

- (NSUInteger)hash {
  return self.path.hash ^ self.revision.hash;
}

@end

NS_ASSUME_NONNULL_END
