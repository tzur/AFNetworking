// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSFileManager+LTKit.h"

@implementation NSFileManager (LTKit)

+ (NSString *)lt_documentsDirectory {
  static NSString *documentsDirectory;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    documentsDirectory = [paths firstObject];
  });

  return documentsDirectory;
}

- (BOOL)lt_writeDictionary:(NSDictionary *)dictionary toFile:(NSString *)path {
  return [dictionary writeToFile:path atomically:YES];
}

- (NSDictionary *)lt_dictionaryWithContentsOfFile:(NSString *)path {
  return [NSDictionary dictionaryWithContentsOfFile:path];
}

- (BOOL)lt_writeData:(NSData *)data toFile:(NSString *)path options:(NSDataWritingOptions)options
               error:(NSError *__autoreleasing *)error {
  return [data writeToFile:path options:options error:error];
}

- (NSData *)lt_dataWithContentsOfFile:(NSString *)path options:(NSDataReadingOptions)options
                                error:(NSError *__autoreleasing *)error {
  return [NSData dataWithContentsOfFile:path options:options error:error];
}

- (NSArray *)lt_globPath:(NSString *)path recursively:(BOOL)recursively
           withPredicate:(NSPredicate *)predicate error:(NSError *__autoreleasing *)error {
  NSURL *url = [NSURL fileURLWithPath:path];
  NSDirectoryEnumerationOptions options = recursively ?
      NSDirectoryEnumerationSkipsSubdirectoryDescendants : 0;
  NSDirectoryEnumerator *enumerator =
      [self enumeratorAtURL:url includingPropertiesForKeys:@[NSURLNameKey] options:options
               errorHandler:^BOOL(NSURL *url, NSError *enumerationError) {
                 if (enumerationError) {
                   if (error) {
                     *error = [NSError lt_errorWithCode:LTErrorCodeFileUnknownError
                                                    url:url
                                        underlyingError:enumerationError];
                   }
                   return NO;
                 }
                 return YES;
               }];

  NSMutableArray *files = [NSMutableArray array];

  for (NSURL *fileURL in enumerator) {
    NSString *filename;
    [fileURL getResourceValue:&filename forKey:NSURLNameKey error:nil];

    if ([predicate evaluateWithObject:filename]) {
      [files addObject:filename];
    }
  }

  return [files copy];
}

- (BOOL)lt_skipBackup:(BOOL)skipBackup forItemAtURL:(NSURL *)url
                error:(NSError *__autoreleasing *)error {
  if (![self fileExistsAtPath:url.path]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileNotFound url:url];
    }
    return NO;
  }

  return [url setResourceValue:@(skipBackup) forKey:NSURLIsExcludedFromBackupKey error:error];
}

@end
