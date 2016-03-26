// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAlbum.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNFileSystemDirectoryDescriptor, PTNFileSystemFileDescriptor;

/// An array of \c PTNFileSystemDirectoryDescriptor objects.
typedef NSArray<PTNFileSystemDirectoryDescriptor *> PTNFileSystemSubdirectories;

/// An array of \c PTNFileSystemFileDescriptor objects.
typedef NSArray<PTNFileSystemFileDescriptor *> PTNFileSystemFiles;

/// Represents an album in the File System, including directories as subalbums and regular files as
/// assets.
@interface PTNFileSystemAlbum : NSObject <PTNAlbum>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a file system album located at the given \c path (which must be a \c fileURL) with
/// the \c subdirectories array to be handled as subalbums and \c files array to be handled as
/// assets.
- (instancetype)initWithPath:(NSURL *)path
              subdirectories:(PTNFileSystemSubdirectories *)subdirectories
                       files:(PTNFileSystemFiles *)files NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
