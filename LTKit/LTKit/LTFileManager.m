// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFileManager.h"

@implementation LTFileManager

+ (instancetype)sharedManager {
  static LTFileManager *instance;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[LTFileManager alloc] init];
  });

  return instance;
}

- (BOOL)writeData:(NSData *)data toFile:(NSString *)path options:(NSDataWritingOptions)options
            error:(NSError *__autoreleasing *)error {
  return [data writeToFile:path options:options error:error];
}

- (NSData *)dataWithContentsOfFile:(NSString *)path options:(NSDataReadingOptions)options
                             error:(NSError *__autoreleasing *)error {
  return [NSData dataWithContentsOfFile:path options:options error:error];
}

- (UIImage *)imageWithContentsOfFile:(NSString *)path {
  return [UIImage imageWithContentsOfFile:path];
}

@end
