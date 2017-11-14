// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "LTSpectaTemporaryPathHook.h"

#import <Specta/SpectaUtility.h>

NS_ASSUME_NONNULL_BEGIN

/// Specta hook which removes the temporary path from the file system after each spec that created a
/// temporary path.
@interface LTSpectaTemporaryPathHook ()

/// Returns given \c relativePath appended to the spec temporary base directory. The spec temporary
/// base directory depends on the specific spec currently running, so there's no concern for files
/// overwriting each other. If the spec temporary base directory doesn't exist it is created.
+ (NSString *)temporaryPath:(NSString *)relativePath;

/// Returns \c YES if the given \c relativePath to the spec temporary base directory exists.
+ (BOOL)fileExistsInTemporaryPath:(NSString *)relativePath;

@end

NSString *LTTemporaryPath(NSString *relativePath) {
  return [LTSpectaTemporaryPathHook temporaryPath:relativePath];
}

BOOL LTFileExistsInTemporaryPath(NSString *relativePath) {
  return [LTSpectaTemporaryPathHook fileExistsInTemporaryPath:relativePath];
}

@implementation LTSpectaTemporaryPathHook

static NSString * _Nullable _temporaryPath;

+ (void)beforeEach {
  _temporaryPath = nil;
}

+ (void)afterEach {
  if (_temporaryPath) {
    [[NSFileManager defaultManager] removeItemAtPath:nn(_temporaryPath) error:nil];
    _temporaryPath = nil;
  }
}

+ (NSString *)temporaryPath:(NSString *)relativePath {
  if (!_temporaryPath) {
    NSString *currentSpec = NSStringFromClass(nn([SPTCurrentSpec class]));
    _temporaryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:currentSpec];
    [[NSFileManager defaultManager] createDirectoryAtPath:nn(_temporaryPath)
                              withIntermediateDirectories:YES attributes:nil error:nil];
  }
  return [nn(_temporaryPath) stringByAppendingPathComponent:relativePath];
}

+ (BOOL)fileExistsInTemporaryPath:(NSString *)relativePath {
  NSString *path = [LTSpectaTemporaryPathHook temporaryPath:relativePath];
  return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

@end

NS_ASSUME_NONNULL_END
