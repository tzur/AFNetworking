// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

@class LTPath, PTNFileSystemFileDescriptor, PTNFileSystemDirectoryDescriptor;

/// Creates a \c PTNFileSystemFileDescriptor with its path set to
/// \c PTNFileSystemPathFromString(path).
PTNFileSystemFileDescriptor *PTNFileSystemFileFromString(NSString *path);

/// Creates a \c PTNFileSystemFileDescriptor with its path set to
/// \c PTNFileSystemPathFromFileURL(path).
PTNFileSystemFileDescriptor *PTNFileSystemFileFromFileURL(NSURL *url);

/// Creates a \c PTNFileSystemDirectoryDescriptor with its path set to
/// \c PTNFileSystemPathFromString(path).
PTNFileSystemDirectoryDescriptor *PTNFileSystemDirectoryFromString(NSString *path);

/// Creates a \c PTNFileSystemDirectoryDescriptor with its path set to
/// \c PTNFileSystemPathFromFileURL(path).
PTNFileSystemDirectoryDescriptor *PTNFileSystemDirectoryFromString(NSURL *url);

/// Returns \c NSString that is a path for video with 16x16 dimensions and approximately 1 second
/// duration.
NSURL *PTNOneSecondVideoPath(void);
