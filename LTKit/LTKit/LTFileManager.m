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

- (UIImage *)imageWithContentsOfFile:(NSString *)path {
  return [UIImage imageWithContentsOfFile:path];
}

- (NSArray *)globPath:(NSString *)path recursively:(BOOL)recursively
        withPredicate:(NSPredicate *)predicate error:(NSError *__autoreleasing *)error {
  NSFileManager *fileManager = [JSObjection defaultInjector][[NSFileManager class]];

  NSURL *url = [NSURL fileURLWithPath:path];
  NSDirectoryEnumerationOptions options = recursively ?
      NSDirectoryEnumerationSkipsSubdirectoryDescendants : 0;
  NSDirectoryEnumerator *enumerator =
      [fileManager enumeratorAtURL:url
        includingPropertiesForKeys:@[NSURLNameKey]
                           options:options
                      errorHandler:^BOOL(NSURL *url, NSError *enumerationError) {
                        if (enumerationError) {
                          if (error) {
                            *error = [NSError errorWithDomain:kLTKitErrorDomain
                                                         code:LTErrorFileError
                                                     userInfo:@{NSFilePathErrorKey:
                                                                  url ?: [NSNull null],
                                                                NSUnderlyingErrorKey:
                                                                  enumerationError,
                                                                }];
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

@end
