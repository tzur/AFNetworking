// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Represents a unique Dropbox entry with the pair \c path and \c revision.
/// Dropbox may keep several revisions for each file. These represent different versions of the
/// file caused by multiple edits or conflicts in shared files. This causes the \c path property
/// alone not to suffice when attempting to describe a specific file in a one-to-one manner.
@interface PTNDropboxEntry : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Creates a new \c PTNDropboxEntry with \c path and \c revision. The \c path is the relative path
/// in the Dropbox file system to the file from either the Dropbox root folder or the Application
/// folder (as specified when obtaining a Dropbox session) and \c revision is a unique identifier
/// for the current revision of a file that can be used to detect changes and avoid conflicts.
/// If the given \c revision is \c nil, the entry refers to the latest revision of the file
/// represented by \c path.
+ (PTNDropboxEntry *)entryWithPath:(NSString *)path andRevision:(nullable NSString *)revision;

/// Creates a new \c PTNDropboxEntry with \c path as the relative path in the Dropbox file system to
/// the file from either the Dropbox root folder or the Application folder (as specified when
/// obtaining a Dropbox session) and \c revision as \c nil, thus the entry refers to the latest
/// revision of the file represented by \c path.
/// This is equivalent to calling \c -[PTNDropboxEntry entryWithPath:path revision:nil].
/// @see -[PTNDropboxEntry entryWithPath:revision:].
+ (PTNDropboxEntry *)entryWithPath:(NSString *)path;

/// Relative path of the file in the Dropbox file system from either the Dropbox root folder or the
/// Application folder (as specified when obtaining a Dropbox session).
@property (readonly, nonatomic) NSString *path;

/// Revision of the file in the Dropbox file system. A unique identifier for the current revision of
/// a file that can be used to detect changes and avoid conflicts.
/// If \c nil, the entry refers to the latest revision of the file represented by \c path.
@property (readonly, nonatomic, nullable) NSString *revision;

@end

NS_ASSUME_NONNULL_END
