// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "LTPath.h"

#import "LTBidirectionalMap.h"
#import "NSFileManager+LTKit.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTPath

/// Scheme of relativeURLs produces and given to \c LTPath.
static NSString * const kPathScheme = @"com.lightricks.path";

- (instancetype)initWithBaseDirectory:(LTPathBaseDirectory)baseDirectory
                      andRelativePath:(NSString *)relativePath {
  if (self = [super init]) {
    _baseDirectory = baseDirectory;
    _relativePath = [self absolutePathWithPath:relativePath].stringByStandardizingPath;
  }
  return self;
}

- (NSString *)absolutePathWithPath:(NSString *)path {
  if ([path hasPrefix:@"/"]) {
    return path;
  } else {
    return [@"/" stringByAppendingString:path];
  }
}

+ (instancetype)pathWithPath:(NSString *)path {
  return [[LTPath alloc] initWithBaseDirectory:LTPathBaseDirectoryNone andRelativePath:path];
}

+ (instancetype)pathWithBaseDirectory:(LTPathBaseDirectory)baseDirectory
                      andRelativePath:(NSString *)relativePath {
  return [[LTPath alloc] initWithBaseDirectory:baseDirectory andRelativePath:relativePath];
}

+ (nullable instancetype)pathWithRelativeURL:(NSURL *)relativeURL {
  if (![relativeURL.scheme isEqualToString:kPathScheme]) {
    return nil;
  }

  NSNumber *key = [[self baseDirectoryToName] keyForObject:relativeURL.host];
  if (!key) {
    return nil;
  }

  return [[LTPath alloc] initWithBaseDirectory:key.unsignedIntegerValue
                               andRelativePath:relativeURL.path];
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

- (NSURL *)relativeURL {
  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.scheme = kPathScheme;
  components.host = [self.class baseDirectoryToName][@(self.baseDirectory)];
  components.path = self.relativePath;
  return components.URL;
}

- (LTPath *)pathByAppendingPathComponent:(NSString *)pathComponent {
  NSString *relativePath = [self.relativePath stringByAppendingPathComponent:pathComponent];
  return [LTPath pathWithBaseDirectory:self.baseDirectory andRelativePath:relativePath];
}

- (LTPath *)pathByAppendingPathExtension:(NSString *)pathExtension {
  NSString *relativePath = [self.relativePath stringByAppendingPathExtension:pathExtension];
  return [LTPath pathWithBaseDirectory:self.baseDirectory andRelativePath:relativePath];
}

#pragma mark -
#pragma mark Base directory mapping
#pragma mark -

+ (LTBidirectionalMap<NSNumber *, NSString *> *)baseDirectoryToName {
  static LTBidirectionalMap *map;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = [LTBidirectionalMap mapWithDictionary:@{
      @(LTPathBaseDirectoryNone): @"none",
      @(LTPathBaseDirectoryTemp): @"temp",
      @(LTPathBaseDirectoryDocuments): @"documents",
      @(LTPathBaseDirectoryMainBundle): @"mainbundle",
      @(LTPathBaseDirectoryCaches): @"caches",
      @(LTPathBaseDirectoryApplicationSupport): @"applicationsupport",
    }];
  });
  
  return map;
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
