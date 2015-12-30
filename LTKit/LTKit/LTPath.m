// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "LTPath.h"

#import "NSFileManager+LTKit.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTPath

- (instancetype)initWithBaseDirectory:(LTPathBaseDirectory)baseDirectory
                      andRelativePath:(NSString *)relativePath {
  if (self = [super init]) {
    _baseDirectory = baseDirectory;
    _relativePath = relativePath;
  }
  return self;
}

+ (instancetype)pathWithPath:(NSString *)path {
  return [[LTPath alloc] initWithBaseDirectory:LTPathBaseDirectoryNone andRelativePath:path];
}

+ (instancetype)pathWithBaseDirectory:(LTPathBaseDirectory)baseDirectory
                      andRelativePath:(NSString *)relativePath {
  return [[LTPath alloc] initWithBaseDirectory:baseDirectory andRelativePath:relativePath];
}

- (NSString *)baseDirectoryPath {
  switch (self.baseDirectory) {
    case LTPathBaseDirectoryNone:
      return @"";
    case LTPathBaseDirectoryTemp:
      return NSTemporaryDirectory();
    case LTPathBaseDirectoryDocuments:
      return [NSFileManager lt_documentsDirectory];
    case LTPathBaseDirectoryMainBundle:
      return [[NSBundle mainBundle] bundlePath];
    case LTPathBaseDirectoryApplicationSupport:
      return [NSFileManager lt_applicationSupportDirectory];
    case LTPathBaseDirectoryCaches:
      return [NSFileManager lt_cachesDirectory];
  }
}

- (NSString *)path {
  return [[self baseDirectoryPath] stringByAppendingPathComponent:self.relativePath];
}

- (NSURL *)url {
  return [NSURL fileURLWithPath:self.path];
}

- (LTPath *)filePathByAppendingPathComponent:(NSString *)pathComponent {
  NSString *relativePath = [self.relativePath stringByAppendingPathComponent:pathComponent];
  return [LTPath pathWithBaseDirectory:self.baseDirectory andRelativePath:relativePath];
}

- (LTPath *)filePathByAppendingPathExtension:(NSString *)pathExtension {
  NSString *relativePath = [self.relativePath stringByAppendingPathExtension:pathExtension];
  return [LTPath pathWithBaseDirectory:self.baseDirectory andRelativePath:relativePath];
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, path: %@>", self.class, self, self.path];
}

- (NSUInteger)hash {
  return self.baseDirectory ^ self.relativePath.hash;
}

- (BOOL)isEqual:(LTPath *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return self.baseDirectory == object.baseDirectory &&
      [self.relativePath isEqual:object.relativePath];
}

@end

NS_ASSUME_NONNULL_END
