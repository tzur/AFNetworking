// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

@class DBMetadata;

NS_ASSUME_NONNULL_BEGIN

/// Creates a fake Dropbox metadata object with the given \c path and \c revision.
DBMetadata *PTNDropboxCreateMetadata(NSString *path, NSString * _Nullable revision);

/// Creates a fake Dropbox metadata object with the given \c path and \c revision and setting
/// \c isDirectory to \c NO.
DBMetadata *PTNDropboxCreateFileMetadata(NSString *path, NSString * _Nullable revision);

/// Creates a fake Dropbox metadata object with the given \c path, \c revision and \c lastModified
/// and setting \c isDirectory to \c NO.
DBMetadata *PTNDropboxCreateFileMetadataWithModificationDate(NSString *path,
                                                             NSString * _Nullable revision,
                                                             NSDate * _Nullable lastModified);

/// Creates a fake Dropbox metadata object with the given \c path and setting \c isDirectory to
/// \c YES.
DBMetadata *PTNDropboxCreateDirectoryMetadata(NSString *path);

/// Creates an error with \c "Dropbox" domain \c 0 error code and \c path in the info matching the
/// \c "path" key.
NSError *PTNDropboxErrorWithPathInfo(NSString *path);

NS_ASSUME_NONNULL_END
