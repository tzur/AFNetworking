// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "LTSpectaTemporaryPathHook.h"

#import <Specta/SpectaUtility.h>

NS_ASSUME_NONNULL_BEGIN

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
