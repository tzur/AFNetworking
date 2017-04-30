// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

@class LTPath, PTNFileSystemFileDescriptor, PTNFileSystemDirectoryDescriptor;

/// Creates a \c LTPath object with base directory set to \c PTNPathBaseDirectoryNone and relative
/// path set to \c path.
LTPath *PTNFileSystemPathFromString(NSString *path);

/// Creates a \c PTNFileSystemFileDescriptor with its path set to
/// \c PTNFileSystemPathFromString(path).
PTNFileSystemFileDescriptor *PTNFileSystemFileFromString(NSString *path);

/// Creates a \c PTNFileSystemDirectoryDescriptor with its path set to
/// \c PTNFileSystemPathFromString(path).
PTNFileSystemDirectoryDescriptor *PTNFileSystemDirectoryFromString(NSString *path);

/// Returns \c NSString that is a path for video with 16x16 dimensions and approximately 1 second
/// duration.
NSURL *PTNOneSecondVideoPath();
