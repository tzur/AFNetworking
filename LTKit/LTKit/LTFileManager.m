// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFileManager.h"

@interface LTFileManager ()

/// Path to the documents directory of the app.
@property (strong, readwrite, nonatomic) NSString *documentsDirectory;

@end

@implementation LTFileManager

objection_register_singleton(LTFileManager);

+ (NSString *)documentsDirectory {
  static NSString *documentsDirectory;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    documentsDirectory = [paths firstObject];
  });

  return documentsDirectory;
}

- (BOOL)writeData:(NSData *)data toFile:(NSString *)path options:(NSDataWritingOptions)options
            error:(NSError *__autoreleasing *)error {
  return [data writeToFile:path options:options error:error];
}

- (NSData *)dataWithContentsOfFile:(NSString *)path options:(NSDataReadingOptions)options
                             error:(NSError *__autoreleasing *)error {
  return [NSData dataWithContentsOfFile:path options:options error:error];
}

- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)recursively
                        error:(NSError *__autoreleasing *)error {
  NSFileManager *fileManager = [JSObjection defaultInjector][[NSFileManager class]];
  return [fileManager createDirectoryAtPath:path withIntermediateDirectories:recursively
                                 attributes:nil error:error];
}

- (UIImage *)imageWithContentsOfFile:(NSString *)path {
  return [UIImage imageWithContentsOfFile:path];
}

@end
