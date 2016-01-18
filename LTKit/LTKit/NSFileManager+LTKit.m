// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSFileManager+LTKit.h"

NS_ASSUME_NONNULL_BEGIN

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

+ (NSString *)lt_cachesDirectory {
  static NSString *cachesDirectory;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    cachesDirectory = [paths firstObject];
  });

  return cachesDirectory;
}

+ (NSString *)lt_applicationSupportDirectory {
  static NSString *applicationSupportDirectory;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                         NSUserDomainMask, YES);
    applicationSupportDirectory = [paths firstObject];
  });

  return applicationSupportDirectory;
}

- (BOOL)lt_directoryExistsAtPath:(NSString *)path {
  BOOL isDirectory;
  return [self fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory;
}

- (BOOL)lt_writeDictionary:(NSDictionary *)dictionary toFile:(NSString *)path
                     error:(NSError *__autoreleasing *)error {
  NSError *serializationError;
  NSData *data = [NSPropertyListSerialization dataWithPropertyList:dictionary
                                                            format:NSPropertyListXMLFormat_v1_0
                                                           options:0 error:&serializationError];
  if (!data || serializationError) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileWriteFailed
                                    path:path underlyingError:serializationError];
    }
    return NO;
  }

  NSError *writeError;
  if (![self lt_writeData:data toFile:path options:NSDataWritingAtomic error:&writeError]) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileWriteFailed
                                    path:path underlyingError:writeError];
    }
    return NO;
  }

  return YES;
}

- (nullable NSDictionary *)lt_dictionaryWithContentsOfFile:(NSString *)path
                                                     error:(NSError *__autoreleasing *)error {
  NSError *readError;
  NSData *data = [self lt_dataWithContentsOfFile:path
                                         options:NSDataReadingUncached error:&readError];
  if (!data || readError) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed
                                    path:path underlyingError:readError];
    }
    return nil;
  }

  NSError *deserializationError;
  NSDictionary *dictionary = [NSPropertyListSerialization
                              propertyListWithData:data options:NSPropertyListImmutable
                              format:nil error:&deserializationError];
  if (!dictionary || deserializationError) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileReadFailed
                                    path:path underlyingError:deserializationError];
    }
    return nil;
  }

  return dictionary;
}

- (BOOL)lt_writeData:(NSData *)data toFile:(NSString *)path options:(NSDataWritingOptions)options
               error:(NSError *__autoreleasing *)error {
  return [data writeToFile:path options:options error:error];
}

- (nullable NSData *)lt_dataWithContentsOfFile:(NSString *)path
                                       options:(NSDataReadingOptions)options
                                         error:(NSError *__autoreleasing *)error {
  return [NSData dataWithContentsOfFile:path options:options error:error];
}

- (nullable NSArray<NSString *> *)lt_globPath:(NSString *)path
                                  recursively:(BOOL)recursively
                                withPredicate:(NSPredicate *)predicate
                                        error:(NSError *__autoreleasing *)error {
  NSMutableArray<NSError *> *globErrors = [NSMutableArray array];

  NSURL *url = [NSURL fileURLWithPath:path];
  NSDirectoryEnumerationOptions options = recursively ? 0 :
      NSDirectoryEnumerationSkipsSubdirectoryDescendants;
  NSDirectoryEnumerator *enumerator =
      [self enumeratorAtURL:url includingPropertiesForKeys:@[NSURLNameKey] options:options
               errorHandler:^BOOL(NSURL *enumerationUrl, NSError *enumerationError) {
                 if (enumerationError && error) {
                   NSError *globError = [NSError lt_errorWithCode:LTErrorCodeFileUnknownError
                                                              url:enumerationUrl
                                                  underlyingError:enumerationError];
                   [globErrors addObject:globError];
                 }
                 return YES;
               }];

  NSMutableArray<NSString *> *files = [NSMutableArray array];

  for (NSURL *fileURL in enumerator) {
    NSString *filename;
    NSError *resourceError;
    if (![fileURL getResourceValue:&filename forKey:NSURLNameKey error:&resourceError]) {
      NSError *globError = [NSError lt_errorWithCode:LTErrorCodeFileUnknownError
                                                 url:fileURL
                                     underlyingError:resourceError];
      [globErrors addObject:globError];
      continue;
    }

    if ([predicate evaluateWithObject:filename]) {
      [files addObject:filename];
    }
  }

  if (globErrors.count) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeFileUnknownError path:path
                        underlyingErrors:globErrors];
    }
    return nil;
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

- (uint64_t)lt_totalStorage {
  return [[[self storageDictionary] objectForKey:NSFileSystemSize] unsignedLongLongValue];
}

- (uint64_t)lt_freeStorage {
  return [[[self storageDictionary] objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
}

- (NSDictionary *)storageDictionary {
  NSError *error;
  NSDictionary *dictionary =
      [self attributesOfFileSystemForPath:[NSFileManager lt_documentsDirectory] error:&error];
  if (error) {
    LogError(@"Error retrieving device storage information: %@", error.description);
    return nil;
  }

  return dictionary;
}

@end

NS_ASSUME_NONNULL_END
