// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSFileManager+Bazaar.h"

#import <LTKit/NSArray+Functional.h>

#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSFileManager (Bazaar)

- (RACSignal *)bzr_retrieveFilesSizes:(NSArray<NSString *> *)filePaths {
  return [[[self bzr_retrieveFilesAttributes:filePaths]
      tryMap:^RACTuple * _Nullable(RACTuple *attributesTuple, NSError **error) {
        RACTupleUnpack(NSString *filePath, NSDictionary *fileAttributes) = attributesTuple;
        NSNumber *fileSize = fileAttributes[NSFileSize];
        if (!fileSize) {
          NSString *description =
              [NSString stringWithFormat:@"File size is not specified in attributes for item at "
               "path %@, item type is %@", filePath, fileAttributes[NSFileType]];
          *error = [NSError lt_errorWithCode:BZRErrorCodeFileAttributesRetrievalFailed path:filePath
                                 description:description];
          return nil;
        }
        return [RACTuple tupleWithObjects:filePath, fileSize, nil];
      }]
      setNameWithFormat:@"%@ -bzr_retrieveFilesSizes", self.description];
}

- (RACSignal *)bzr_retrieveFilesAttributes:(NSArray<NSString *> *)filePaths {
  return [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    for (NSString *filePath in filePaths) {
      NSError *error;
      NSDictionary *attributes = [self attributesOfItemAtPath:filePath error:&error];
      if (!attributes) {
        error = [NSError lt_errorWithCode:BZRErrorCodeFileAttributesRetrievalFailed path:filePath
                          underlyingError:error];
        [subscriber sendError:error];
        return nil;
      }

      [subscriber sendNext:[RACTuple tupleWithObjects:filePath, attributes, nil]];
    }

    [subscriber sendCompleted];
    return nil;
  }]
      subscribeOn:[RACScheduler scheduler]]
      setNameWithFormat:@"%@ -bzr_retrieveFilesAttributes", self.description];
}

- (RACSignal *)bzr_enumerateDirectoryAtPath:(NSString *)directoryPath {
  return [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSError *error;
    NSDirectoryEnumerator<NSString *> *enumerator =
        [self bzr_directoryEnumeratorAtPath:directoryPath error:&error];
    if (!enumerator) {
      [subscriber sendError:error];
      return nil;
    }

    for (NSString *item in enumerator) {
      NSString *itemPath = [directoryPath stringByAppendingPathComponent:item];
      BOOL isDirectory;
      if (![self fileExistsAtPath:itemPath isDirectory:&isDirectory] || isDirectory) {
        continue;
      }
      [subscriber sendNext:[RACTuple tupleWithObjects:directoryPath, item, nil]];
    }
    [subscriber sendCompleted];
    return nil;
  }]
      subscribeOn:[RACScheduler scheduler]]
      setNameWithFormat:@"%@ -bzr_enumerateDirectoryAtPath: %@", self.description, directoryPath];
}

- (NSDirectoryEnumerator<NSString *> *)bzr_directoryEnumeratorAtPath:(NSString *)directoryPath
    error:(NSError * __autoreleasing *)error {
  BOOL isDirectory;
  if (![self fileExistsAtPath:directoryPath isDirectory:&isDirectory] || !isDirectory) {
    NSString *description =
        [NSString stringWithFormat:@"Item at path %@ does not exist or is not a directory",
         directoryPath];
    *error = [NSError lt_errorWithCode:BZRErrorCodeDirectoryEnumrationFailed path:directoryPath
                           description:description];
    return nil;
  }

  NSDirectoryEnumerator<NSString *> *enumerator = [self enumeratorAtPath:directoryPath];
  if (!enumerator) {
    NSString *description =
        [NSString stringWithFormat:@"Failed to create enumartor for directory at path %@",
         directoryPath];
    *error = [NSError lt_errorWithCode:BZRErrorCodeDirectoryEnumrationFailed
                                  path:directoryPath description:description];
  }
  return enumerator;
}

- (RACSignal *)bzr_deleteItemAtPathIfExists:(NSString *)path {
  return [[[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSError *error;
    if ([self fileExistsAtPath:path isDirectory:nil]) {
      if (![self removeItemAtPath:path error:&error] || error) {
        error = [NSError lt_errorWithCode:LTErrorCodeFileRemovalFailed path:path
                          underlyingError:error];
        [subscriber sendError:error];
        return nil;
      }
    }
    [subscriber sendCompleted];
    return nil;
  }]
      subscribeOn:[RACScheduler scheduler]]
      setNameWithFormat:@"%@ -bzr_deleteItemAtPathIfExists: %@", self.description, path];
}

@end

NS_ASSUME_NONNULL_END
