// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for reactive file archivers.
@protocol BZRFileArchiver <NSObject>

/// Creates a new archive file at \c archivePath containing the files at \c filePaths. The default
/// archiving options will be used.
///
/// Returns a signal that initiate archiving upon subscription. The signal may send zero or more
/// \c LTProgress values indicating the progress of the archiving. When archiving is completed the
/// signal sends an \c LTProgress value containing the path to the archive file as its \c result
/// property and then completes. The signal errs if archiving failed.
///
/// @return <tt>RACSignal<LTProgress<NSString>></tt>
- (RACSignal *)archiveFiles:(NSArray<NSString *> *)filePaths
            toArchiveAtPath:(NSString *)archivePath;

/// Creates a new archive file at \c archivePath containing all the files in \c directory. The
/// resulting archive file will contain a root directory parallel to \c directory.
///
/// Returns a signal that initiates archiving upon subscription. The signal may send zero or more
/// \c LTProgress values indicating the progress of the archiving. When archiving is completed the
/// signal sends an \c LTProgress value containing the path to the archive file as its \c result
/// property and then completes. The signal errs if archiving failed.
///
/// @return <tt>RACSignal<LTProgress<NSString>></tt>
- (RACSignal *)archiveContentsOfDirectory:(NSString *)directory
                          toArchiveAtPath:(NSString *)archivePath;

/// Unarchives the archive at \c archivePath to the \c targetDirectory. The default archiving
/// options will be used.
///
/// Returns a signal that initates unarchiving upon subscription. The signal may send zero or more
/// \c LTProgress values indicating the progress of the unarchiving process. When unarchiving is
/// completed the signal sends an \c LTProgress value containing the path to the target directory as
/// its \c result property and then completes. The signal errs if unarchiving failed.
///
/// @return <tt>RACSignal<LTProgress<NSString>></tt>
- (RACSignal *)unarchiveArchiveAtPath:(NSString *)archivePath
                          toDirectory:(NSString *)targetDirectory;

@end

NS_ASSUME_NONNULL_END
