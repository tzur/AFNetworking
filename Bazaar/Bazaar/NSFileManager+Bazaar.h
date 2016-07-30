// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Adds utility methods used by Bazaar.
@interface NSFileManager (Bazaar)

/// Collects the sizes of the files at \c filePaths and delivers them one by one.
///
/// Returns a signal that on subscription collects file attributes for the files specified by
/// \c filePaths and sends them one by one as \c RACTuple values each containing the name of a file
/// as an \c NSString and file size as an \c NSNumber. The signal completes when the sizes of all
/// files in \c filePaths were delivered and errs if failed to retrieve attributes of any of the
/// files.
///
/// @return <tt>RACSignal<RAACTuple<NSString, NSNumber>></tt>
///
/// @note Subscription is performed on a new scheduler in order to not block the subscriber thread,
/// but the signal does not support subscription cancellation.
- (RACSignal *)bzr_retrieveFilesSizes:(NSArray<NSString *> *)filePaths;

/// Recursively enumerates the directory at \c directoryPath and locates all file items in that
/// directory and its sub-directories.
///
/// Returns a signal that upon subscription starts enumerating the directory. The signal sends a
/// series of \c NSString each is a path to an item under \c directoryPath and is relative to
/// \c directoryPath. The signal completes after all items in \c directoryPath were enumerated and
/// errs if \c directoryPath does not exist or it's not a directory.
///
/// @return <tt>RACSignal<NSArray<NSString>></tt>
///
/// @note The provided array does not contains entries for sub-directories. For example if
/// \c directoryPath is "/foo" and the "foo" directory contains the files "baz" and "bar/baz" the
/// provided array will be \c ["baz", "bar/baz"] and not \c ["baz", "bar", "bar/baz"].
///
/// @note Subscription is performed on a new scheduler in order to not block the subscriber thread,
/// but the signal does not support subscription cancellation.
- (RACSignal *)bzr_enumerateDirectoryAtPath:(NSString *)directoryPath;

/// Deletes the item at the specified path if it exists.
///
/// Returns a signal that deletes the item at \c path upon subscription and then completes. The
/// signal errs if deletion failed.
///
/// @return <tt>RACSignal</tt>
///
/// @note Subscription is performed on a new scheduler in order to not block the subscriber thread,
/// but the signal does not support subscription cancellation.
- (RACSignal *)bzr_deleteItemAtPathIfExists:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
