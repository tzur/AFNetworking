// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNAlbum.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNDropboxDirectoryDescriptor, PTNDropboxFileDescriptor;

/// Array of \c PTNDropboxDirectoryDescriptor objects.
typedef NSArray<PTNDropboxDirectoryDescriptor *> PTNDropboxSubdirectories;

/// Array of \c PTNDropboxFileDescriptor objects.
typedef NSArray<PTNDropboxFileDescriptor *> PTNDropboxFiles;

/// Represents an album in the Dropbox file system. Subdirectories are treated as subalbums and
/// files are treated as assets.
@interface PTNDropboxAlbum : NSObject <PTNAlbum>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a Dropbox album located at the given \c path (which must be a dropbox URL) with
/// the \c subdirectories array to be handled as subalbums and \c files array to be handled as
/// assets.
- (instancetype)initWithPath:(NSURL *)path
              subdirectories:(PTNDropboxSubdirectories *)subdirectories
                       files:(PTNDropboxFiles *)files NS_DESIGNATED_INITIALIZER;


@end

NS_ASSUME_NONNULL_END
