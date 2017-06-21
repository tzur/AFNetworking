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
          if (error) {
            *error = [NSError lt_errorWithCode:BZRErrorCodeFileAttributesRetrievalFailed
                                          path:filePath
                                   description:@"File size is not specified in attributes for item "
                      "at path %@, item type is %@", filePath, fileAttributes[NSFileType]];
          }
          return nil;
        }
        return [RACTuple tupleWithObjects:filePath, fileSize, nil];
      }]
      setNameWithFormat:@"%@ -bzr_retrieveFilesSizes", self.description];
}

- (RACSignal *)bzr_retrieveFilesAttributes:(NSArray<NSString *> *)filePaths {
  return [[[RACSignal
      createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        for (NSString *filePath in filePaths) {
          NSError *error;
          NSDictionary *attributes = [self attributesOfItemAtPath:filePath error:&error];
          if (!attributes) {
            error = [NSError lt_errorWithCode:BZRErrorCodeFileAttributesRetrievalFailed
                                         path:filePath underlyingError:error];
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
  return [[[RACSignal
      createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
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

- (nullable NSDirectoryEnumerator<NSString *> *)bzr_directoryEnumeratorAtPath:(NSString *)path
    error:(NSError * __autoreleasing *)error {
  BOOL isDirectory;
  if (![self fileExistsAtPath:path isDirectory:&isDirectory] || !isDirectory) {
    if (error) {
      *error = [NSError lt_errorWithCode:BZRErrorCodeDirectoryEnumrationFailed path:path
                             description:@"Item at path %@ does not exist or is not a directory",
                path];
    }
    return nil;
  }

  NSDirectoryEnumerator<NSString *> *enumerator = [self enumeratorAtPath:path];
  if (!enumerator && error) {
    *error = [NSError lt_errorWithCode:BZRErrorCodeDirectoryEnumrationFailed path:path
                           description:@"Failed to create enumartor for directory at path %@",
              path];
  }
  return enumerator;
}

- (RACSignal *)bzr_deleteItemAtPathIfExists:(NSString *)path {
  return [[[RACSignal
      createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSError *itemRemovalError;
        if ([self fileExistsAtPath:path isDirectory:nil]) {
          BOOL success = [self removeItemAtPath:path error:&itemRemovalError];
          if (!success) {
            NSError *error = [NSError lt_errorWithCode:LTErrorCodeFileRemovalFailed path:path
                                       underlyingError:itemRemovalError];
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

- (RACSignal *)bzr_createDirectoryAtPathIfNotExists:(NSString *)path {
  return [[[RACSignal
      createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSError *underlyingError;
        BOOL createDirectorySucceeded =
            [self createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil
                                  error:&underlyingError];
        if (!createDirectorySucceeded) {
          NSError *error = [NSError lt_errorWithCode:BZRErrorCodeDirectoryCreationFailed
                                     underlyingError:underlyingError];
          [subscriber sendError:error];
        } else {
          [subscriber sendCompleted];
        }
        return nil;
      }]
      subscribeOn:[RACScheduler scheduler]]
      setNameWithFormat:@"%@ -bzr_createDirectoryAtPathIfNotExists: %@", self.description, path];
}

- (RACSignal *)bzr_moveItemAtPath:(NSString *)path toPath:(NSString *)targetPath {
  return [[[RACSignal
      createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSError *underlyingError;
        BOOL moveItemSucceeded =
            [self moveItemAtPath:path toPath:targetPath error:&underlyingError];
        if (!moveItemSucceeded) {
          NSError *error = [NSError lt_errorWithCode:BZRErrorCodeMoveItemFailed
                                     underlyingError:underlyingError];
          [subscriber sendError:error];
        } else {
          [subscriber sendCompleted];
        }
        return nil;
      }]
      subscribeOn:[RACScheduler scheduler]]
      setNameWithFormat:@"%@ -bzr_moveItemAtPath: %@ to: %@", self.description, path, targetPath];
}

@end

NS_ASSUME_NONNULL_END
