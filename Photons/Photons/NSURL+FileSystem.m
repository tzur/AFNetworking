// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSURL+FileSystem.h"

#import <LTKit/LTBidirectionalMap.h>
#import <LTKit/LTPath.h>
#import <LTKit/NSURL+Query.h>

NS_ASSUME_NONNULL_BEGIN

@implementation NSURL (FileSystem)

+ (NSString *)ptn_fileSystemScheme {
  return @"com.lightricks.Photons.FileSystem";
}

+ (NSURL *)ptn_fileSystemAssetURLWithPath:(LTPath *)path {
  return [self ptn_fileSystemUrlForType:PTNFileSystemURLTypeAsset andPath:path];
}

+ (NSURL *)ptn_fileSystemAlbumURLWithPath:(LTPath *)path {
  return [self ptn_fileSystemUrlForType:PTNFileSystemURLTypeAlbum andPath:path];
}

+ (NSURL *)ptn_fileSystemUrlForType:(PTNFileSystemURLType)type andPath:(LTPath *)path {
  NSString *baseName = [self ptn_fileSystemBaseTypeToBaseName][@(path.baseDirectory)];
  LTParameterAssert(baseName, @"Unrecognized File System base directory: %lu", (unsigned long)type);

  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.scheme = [NSURL ptn_fileSystemScheme];
  components.host = type == PTNFileSystemURLTypeAsset ? @"asset" : @"album";
  components.queryItems = @[[NSURLQueryItem queryItemWithName:@"base" value:baseName],
                            [NSURLQueryItem queryItemWithName:@"relative" value:path.relativePath]];

  return components.URL;
}

+ (LTBidirectionalMap *)ptn_fileSystemBaseTypeToBaseName {
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
      @(LTPathBaseDirectoryLibrary): @"library"
    }];
  });

  return map;
}

- (nullable LTPath *)ptn_fileSystemAlbumPath {
  if (![self.scheme isEqual:[NSURL ptn_fileSystemScheme]] || ![self.host isEqual:@"album"]) {
    return nil;
  }

  return [self ptn_fileSystemPath];
}

- (nullable LTPath *)ptn_fileSystemAssetPath {
  if (![self.scheme isEqual:[NSURL ptn_fileSystemScheme]] || ![self.host isEqual:@"asset"]) {
    return nil;
  }

  return [self ptn_fileSystemPath];
}

- (nullable LTPath *)ptn_fileSystemPath {
  NSDictionary *query = self.lt_queryDictionary;
  if (!query[@"base"] || !query[@"relative"]) {
    return nil;
  }

  LTBidirectionalMap *map = [self.class ptn_fileSystemBaseTypeToBaseName];
  NSNumber *baseDirectory = [map keyForObject:query[@"base"]];
  if (!baseDirectory) {
    return nil;
  }

  LTPathBaseDirectory base = [baseDirectory unsignedIntegerValue];
  NSString *relative = query[@"relative"];

  return [LTPath pathWithBaseDirectory:base andRelativePath:relative];
}

- (PTNFileSystemURLType)ptn_fileSystemURLType {
  if (![self.scheme isEqual:[NSURL ptn_fileSystemScheme]]) {
    return PTNFileSystemURLTypeInvalid;
  }

  NSDictionary *query = self.lt_queryDictionary;
  if (!query[@"base"] || !query[@"relative"]) {
    return PTNFileSystemURLTypeInvalid;
  }

  if ([self.host isEqual:@"asset"]) {
    return PTNFileSystemURLTypeAsset;
  } else if ([self.host isEqual:@"album"]) {
    return PTNFileSystemURLTypeAlbum;
  }

  return PTNFileSystemURLTypeInvalid;
}

@end

NS_ASSUME_NONNULL_END
