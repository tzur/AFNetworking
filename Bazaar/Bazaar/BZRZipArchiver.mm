// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRZipArchiver.h"

#import <LTKit/NSArray+Functional.h>
#import <ZipArchive/SSZipArchive.h>

#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRZipArchiver ()

/// Underlying archive object.
@property (readonly, nonatomic) SSZipArchive *archive;

@end

@implementation BZRZipArchiver

@synthesize path = _path;
@synthesize password = _password;
@synthesize archivingQueue = _archivingQueue;

#pragma mark -
#pragma mark Initialization
#pragma mark -

+ (nullable instancetype)zipArchiverWithPath:(NSString *)path password:(nullable NSString *)password
                                       error:(NSError * __autoreleasing *)error {
  SSZipArchive *archive = [self openArchiveAtPath:path error:error];
  return archive ? [[self alloc] initWithArchive:archive atPath:path password:password
                                  archivingQueue:nil] : nil;
}

+ (nullable SSZipArchive *)openArchiveAtPath:(NSString *)path
                                       error:(NSError * __autoreleasing *)error {
  SSZipArchive *archive = [[SSZipArchive alloc] initWithPath:path];
  if (![archive open]) {
    if (error) {
      *error = [NSError bzr_errorWithCode:BZRErrorCodeArchiveCreationFailed archivePath:path
                   failingArchiveItemPath:nil underlyingError:nil description:nil];
    }
    return nil;
  }
  return archive;
}

- (instancetype)initWithArchive:(SSZipArchive *)archive atPath:(NSString *)path
                       password:(nullable NSString *)password
                 archivingQueue:(nullable dispatch_queue_t)archivingQueue {
  if (self = [super init]) {
    _archive = archive;
    _path = [path copy];
    _password = [password copy];
    _archivingQueue = archivingQueue ?:
        dispatch_queue_create("com.lightricks.bazaar.zip-archiver", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)dealloc {
  [self.archive close];
}

#pragma mark -
#pragma mark Archiving and Unarchiving
#pragma mark -

- (void)archiveFilesAtPaths:(NSArray<NSString *> *)filePaths
          withArchivedNames:(nullable NSArray<NSString *> *)archivedNames
                fileManager:(NSFileManager *)fileManager
                   progress:(nullable BZRZipArchiveProgressBlock)progress
                 completion:(LTSuccessOrErrorBlock)completion {
  LTParameterAssert(filePaths.count, @"File paths must be specified, got %@", filePaths);
  LTParameterAssert(!archivedNames || archivedNames.count == filePaths.count,
                    @"File paths count and archvied names count must be identical");
  LTParameterAssert(completion, @"Completion block must not be nil");

  [[[[fileManager bzr_retrieveFilesSizes:filePaths]
      map:^NSNumber *(RACTuple *pathAndSize) {
        return pathAndSize.second;
      }]
      collect]
      subscribeNext:^(NSArray<NSNumber *> *fileSizes) {
        [self archiveFilesAtPaths:filePaths withSizes:fileSizes archivedNames:archivedNames
                         progress:progress completion:completion];
      } error:^(NSError *error) {
        completion(NO, error);
      }];
}

- (void)archiveFilesAtPaths:(NSArray<NSString *> *)filePaths
                  withSizes:(NSArray<NSNumber *> *)fileSizes
              archivedNames:(nullable NSArray<NSString *> *)archivedNames
                   progress:(nullable BZRZipArchiveProgressBlock)progress
                 completion:(LTSuccessOrErrorBlock)completion {
  @weakify(self);
  dispatch_async(self.archivingQueue, ^{
    @strongify(self);
    NSNumber *totalBytes = [fileSizes lt_reduce:^NSNumber *(NSNumber *sum, NSNumber *value) {
      return @([sum longLongValue] + [value longLongValue]);
    } initial:@0];
    NSNumber *processedBytes = @0;

    BOOL success = NO;
    BOOL cancelled = NO;
    if (progress && !progress(totalBytes, processedBytes)) {
      cancelled = YES;
    }

    NSError *error;
    for (NSUInteger i = 0; i < filePaths.count && !cancelled; ++i) {
      NSString *archivedName = archivedNames ? archivedNames[i] : nil;
      success = [self archiveFileAtPath:filePaths[i] withArchivedName:archivedName error:&error];
      if (!success) {
        break;
      }

      processedBytes = @([processedBytes longLongValue] + [fileSizes[i] longLongValue]);
      if (progress && !progress(totalBytes, processedBytes)) {
        cancelled = YES;
        success = NO;
        break;
      }
    }

    if (cancelled) {
      error = [NSError bzr_errorWithCode:BZRErrorCodeArchivingCancelled archivePath:self.path
                  failingArchiveItemPath:nil underlyingError:nil
                             description:@"Archive extraction was cancelled"];
    }

    completion(success, error);
  });
}

- (BOOL)archiveFileAtPath:(NSString *)path withArchivedName:(nullable NSString *)archivedName
                    error:(NSError * __autoreleasing *)error {
  if (![self.archive writeFileAtPath:path withFileName:archivedName withPassword:self.password]) {
    if (error) {
      NSString *description = [NSString stringWithFormat:@"Failed to archive item at %@", path];
      *error = [NSError bzr_errorWithCode:BZRErrorCodeItemArchivingFailed archivePath:self.path
                   failingArchiveItemPath:path underlyingError:nil description:description];
    }
    return NO;
  }
  return YES;
}

@end

NS_ASSUME_NONNULL_END
