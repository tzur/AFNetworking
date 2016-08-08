// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRZipArchiving.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol for objects that support unarhciving from zip files.
@protocol BZRZipUnarchiver <BZRZipArchivingHandler>

/// Unarchives the content of the archive file to the folder at \c path. If \c progress is not
/// \c nil it will receive progress updates and its return value will determine whether to continue
/// the archiving or not. On completion the \c completion block will be invoked provided with the
/// completion status.
- (void)unarchiveFilesToPath:(NSString *)path progress:(nullable BZRZipArchiveProgressBlock)progress
                  completion:(LTSuccessOrErrorBlock)completion;

@end

/// Default implementation of the \c BZRZipUnarchiver protocol using \c SSZipArchive.
@interface BZRZipUnarchiver : NSObject <BZRZipUnarchiver>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes an unarchiver that can be used to unarchive the content of the zip file at \c path.
/// If \c password is not \c nil it will be used to encrypt archived files. If \c archivingQueue is
/// not \c nil unarchiving operations will be dispatched on that queue, otherwise a new serial queue
/// will be created.
- (instancetype)initWithPath:(NSString *)path password:(nullable NSString *)password
              archivingQueue:(nullable dispatch_queue_t)archivingQueue NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
