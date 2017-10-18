// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRZipFileArchiver.h"

#import "BZRZipArchiveFactory.h"
#import "BZRZipArchiver.h"
#import "BZRZipUnarchiver.h"
#import "LTProgress+Bazaar.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSFileManager+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRZipFileArchiver ()

/// File manager to use for interacting with the file system.
@property (readonly, nonatomic) NSFileManager *fileManager;

/// Factory used to create archive objects.
@property (readonly, nonatomic) BZRZipArchiveFactory *archiveFactory;

@end

@implementation BZRZipFileArchiver

- (instancetype)init {
  return [self initWithFileManager:[NSFileManager defaultManager]
                    archiveFactory:[[BZRZipArchiveFactory alloc] init]];
}

- (instancetype)initWithFileManager:(NSFileManager *)fileManager {
  return [self initWithFileManager:fileManager archiveFactory:[[BZRZipArchiveFactory alloc] init]];
}

- (instancetype)initWithFileManager:(NSFileManager *)fileManager
                     archiveFactory:(BZRZipArchiveFactory *)archiveFactory {
  if (self = [super init]) {
    _fileManager = fileManager;
    _archiveFactory = archiveFactory;
  }
  return self;
}

- (RACSignal<BZRFileArchivingProgress *> *)archiveFiles:(NSArray<NSString *> *)filePaths
            toArchiveAtPath:(NSString *)archivePath {
  return [self archiveFiles:filePaths toArchiveAtPath:archivePath withArchivedNames:nil];
}

- (RACSignal<BZRFileArchivingProgress *> *)archiveContentsOfDirectory:(NSString *)directoryPath
                                                      toArchiveAtPath:(NSString *)archivePath {
  return [[[[self.fileManager bzr_enumerateDirectoryAtPath:directoryPath]
      map:^RACTuple *(RACTuple *enumerationTuple) {
        NSString *itemRelativePath = enumerationTuple.second;
        NSString *itemFullPath = [directoryPath stringByAppendingPathComponent:itemRelativePath];
        return RACTuplePack(itemFullPath, itemRelativePath);
      }]
      collect]
      flattenMap:^(NSArray<RACTuple *> *tuples) {
        NSArray<NSString *> *filePaths = [tuples valueForKey:@instanceKeypath(RACTuple, first)];
        NSArray<NSString *> *archivedNames = [tuples valueForKey:@instanceKeypath(RACTuple,
                                                                                  second)];
        return [self archiveFiles:filePaths toArchiveAtPath:archivePath
                withArchivedNames:archivedNames];
      }];
}

- (RACSignal<BZRFileArchivingProgress *> *)archiveFiles:(NSArray<NSString *> *)filePaths
    toArchiveAtPath:(NSString *)archivePath
    withArchivedNames:(nullable NSArray<NSString *> *)archivedNames {
  RACSignal *deletionSignal = [self.fileManager bzr_deleteItemAtPathIfExists:archivePath];

  @weakify(self);
  RACSignal<BZRFileArchivingProgress *> *archivingSignal =
      [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        NSError *error;
        id<BZRZipArchiver> archiver = [self.archiveFactory zipArchiverAtPath:archivePath
                                                                withPassword:nil error:&error];
        if (!archiver || error) {
          [subscriber sendError:error];
          return nil;
        }

        RACDisposable *disposable = [[RACDisposable alloc] init];
        [archiver archiveFilesAtPaths:filePaths withArchivedNames:archivedNames
                          fileManager:self.fileManager
                             progress:^BOOL(NSNumber *totalBytes, NSNumber *bytesProcessed) {
          if (!disposable.isDisposed) {
            [subscriber sendNext:[LTProgress progressWithTotalUnitCount:totalBytes
                                                     completedUnitCount:bytesProcessed]];
          }
          return !disposable.isDisposed;
        } completion:^(BOOL success, NSError * _Nullable error) {
          if (disposable.isDisposed) {
            return;
          }

          if (success) {
            [subscriber sendNext:[[LTProgress alloc] initWithResult:archivePath]];
            [subscriber sendCompleted];
          } else {
            [subscriber sendError:error];
          }
        }];
        return disposable;
      }];

  return [[deletionSignal
      concat:archivingSignal]
      subscribeOn:[RACScheduler scheduler]];
}

- (RACSignal<BZRFileArchivingProgress *> *)unarchiveArchiveAtPath:(NSString *)archivePath
                                                      toDirectory:(NSString *)targetDirectory {
  @weakify(self);
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    NSError *error;
    id<BZRZipUnarchiver> unarchiver = [self.archiveFactory zipUnarchiverAtPath:archivePath
                                                                  withPassword:nil error:&error];
    if (!unarchiver || error) {
      [subscriber sendError:error];
      return nil;
    }

    RACDisposable *disposable = [[RACDisposable alloc] init];
    [unarchiver unarchiveFilesToPath:targetDirectory
                            progress:^BOOL(NSNumber *totalBytes, NSNumber *bytesProcessed) {
      if (!disposable.isDisposed) {
        [subscriber sendNext:[LTProgress progressWithTotalUnitCount:totalBytes
                                                 completedUnitCount:bytesProcessed]];
      }
      return !disposable.isDisposed;
    } completion:^(BOOL success, NSError * _Nullable error) {
      if (disposable.isDisposed) {
        return;
      }

      if (success) {
        [subscriber sendNext:[[LTProgress alloc] initWithResult:targetDirectory]];
        [subscriber sendCompleted];
      } else {
        [subscriber sendError:error];
      }
    }];
    return disposable;
  }]
      subscribeOn:[RACScheduler scheduler]];
}

@end

NS_ASSUME_NONNULL_END
