// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Progress block for reporting the progress of zip archiving task.
///
/// The block is provided with a \c totalBytes argument that indicates the total number of bytes to
/// be processed by the archiving task and \c bytesProcessed that indicates the number of bytes
/// processed so far. If the block returns \c YES archiving will continue otherwise it will be
/// cancelled.
typedef BOOL (^BZRZipArchiveProgressBlock)(NSNumber *totalBytes, NSNumber *bytesProcessed);

/// Common protocol for objects that handles archiving or unarchiving of zip files.
@protocol BZRZipArchivingHandler <NSObject>

/// Path to the zip archive file on disk.
@property (readonly, nonatomic) NSString *path;

/// Password used to encrypt archived files.
@property (readonly, nonatomic, nullable) NSString *password;

/// Queue used to dispatch archiving / unarchiving operations on.
@property (readonly, nonatomic) dispatch_queue_t archivingQueue;

@end

NS_ASSUME_NONNULL_END
