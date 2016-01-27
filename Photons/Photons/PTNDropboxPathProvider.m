// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxPathProvider.h"

#import <LTKit/NSString+Hashing.h>

NS_ASSUME_NONNULL_BEGIN

@implementation PTNDropboxPathProvider

- (NSString *)localPathForFileInPath:(NSString *)path revision:(nullable NSString *)revision {
  NSString *name = [path stringByAppendingString:revision ?: @"latest"];;
  return [self uniqueFilePathFromName:name extension:path.pathExtension];
}

- (NSString *)localPathForThumbnailInPath:(NSString *)path size:(CGSize)size {
  NSString *name = [path stringByAppendingString:NSStringFromCGSize(size)];
  return [self uniqueFilePathFromName:name extension:path.pathExtension];
}

- (NSString *)uniqueFilePathFromName:(NSString *)name extension:(NSString *)extension {
  NSString *uniqueFileName = [[name lt_SHA1] stringByAppendingPathExtension:extension];
  return [NSTemporaryDirectory() stringByAppendingPathComponent:uniqueFileName];
}

@end

NS_ASSUME_NONNULL_END
