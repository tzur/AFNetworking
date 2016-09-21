// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRFileArchiver.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRZipArchiveFactory;

@interface BZRZipFileArchiver : NSObject <BZRFileArchiver>

/// Convenience initializer that initializes \c archiveFactory with 
/// \c [[BZRZipArchiveFactory alloc] init].
///
/// @see initWithFileManager:archiveFactory:
- (instancetype)initWithFileManager:(NSFileManager *)fileManager;

/// Initializes the receiver with the given \c fileManager and \c archiveFactory.
///
/// The \c fileManager will be used to interact with the file system when archiving / unarchiving
/// requests are initiated. The \c archiveFactory will be used to create instances of zip archives
/// when archiving \ unarchiving requests are initiated.
- (instancetype)initWithFileManager:(NSFileManager *)fileManager
                     archiveFactory:(BZRZipArchiveFactory *)archiveFactory
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
