// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@protocol BZRZipArchiver, BZRZipUnarchiver;

/// Factory for creating zip archive objects.
@interface BZRZipArchiveFactory : NSObject

/// Creates and returns a new \c BZRZipArchiver that can be used to archive files into a zip archive
/// residing at the given \c path. If \c password is not \c nil it will be used to encrypt files
/// archived using the returned archiver. If an error occurs during the initialization of the
/// archiver it will be reported via \c error if it's not \c nil.
- (nullable id<BZRZipArchiver>)zipArchiverAtPath:(NSString *)path
                                    withPassword:(nullable NSString *)password
                                           error:(NSError **)error;

/// Creates and returns a new \c BZRZipUnarchiver that can be used to unarchive files from a zip
/// archive residing at the given \c path. If \c password is not \c nil it will be used to decrypt
/// files unarchived using the returned unarchiver. If an error occurs during the initialization of
/// the unarchiver it will be reported via \c error if it's not \c nil.
- (nullable id<BZRZipUnarchiver>)zipUnarchiverAtPath:(NSString *)path
                                        withPassword:(nullable NSString *)password
                                               error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
