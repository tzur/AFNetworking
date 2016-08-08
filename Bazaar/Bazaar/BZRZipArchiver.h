// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRZipArchiving.h"

NS_ASSUME_NONNULL_BEGIN

@class SSZipArchive;

/// Protocol for objects that support archiving into zip files.
@protocol BZRZipArchiver <BZRZipArchivingHandler>

/// Archives the files at \c filePaths. \c fileManager is used to fetch metadata on the archived
/// files. If \c archivedNames is not \c nil the names it contains will be used as the names for the
/// archived files inside the archive. If \c progress is not \c nil it will receive progress updates
/// and its return value will determine whether to continue the archiving or not. On completion the
/// \c completion block will be invoked provided with the completion status.
- (void)archiveFilesAtPaths:(NSArray<NSString *> *)filePaths
          withArchivedNames:(nullable NSArray<NSString *> *)archivedNames
                fileManager:(NSFileManager *)fileManager
                   progress:(nullable BZRZipArchiveProgressBlock)progress
                 completion:(LTSuccessOrErrorBlock)completion;

@end

/// Default implementation for the \c BZRZipArchiver protocol using \c SSZipArchive.
@interface BZRZipArchiver : NSObject <BZRZipArchiver>

- (instancetype)init NS_UNAVAILABLE;

/// Creates a new empty zip file at the given \c path and opens it for archiving purpose (if a file
/// already exists at \c path it will be overwritten), then it creates an archiver using the new zip
/// archive is its underlying archive. If \c password is not \c nil it will be used to encrypt files
/// archived using the returned archiver. If \c error is not \c nil and an error occurs during the
/// initialization of the zip archive, \c error will be filled with the relevant error information.
+ (nullable instancetype)zipArchiverWithPath:(NSString *)path password:(nullable NSString *)password
                                       error:(NSError **)error;

/// Initializes the zip archive with the underlying \c archive object. \c archive is assumed to be
/// open for archiving and it will be closed on deallocation. \c path specifies the path to the zip
/// archive file on disk. If \c password is not \c nil it will be used to encrypt archived files.
/// If \c archivingQueue is not \c nil archiving operations will be dispatched on that queue,
/// otherwise a new serial queue will be created.
- (instancetype)initWithArchive:(SSZipArchive *)archive atPath:(NSString *)path
                       password:(nullable NSString *)password
                 archivingQueue:(nullable dispatch_queue_t)archivingQueue NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
