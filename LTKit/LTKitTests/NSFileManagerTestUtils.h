// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Creates a fake \c NSURL that returns the given \c name for \c NSURLNameKey query.
id LTCreateFakeURL(NSString *name);

/// Creates a fake \c NSURL that returns the given \c error when queried for its \c NSURLNameKey
/// query.
id LTCreateFakeURLWithError(NSError *error);

/// Stubs the given \c fileManager mock to return the given \c files for the given \c path, when
/// requested them recursively or not.
void LTStubFileManager(id fileManager, NSURL *path, BOOL recursive, NSArray<NSURL *> *files);

/// Stubs the given \c fileManager mock to return \c error for all the given \c files, when
/// requesting them recursively or not.
void LTStubFileManagerWithError(id fileManager, NSURL *path, BOOL recursive,
                                NSArray<NSURL *> *files, NSError *error);

NS_ASSUME_NONNULL_END
