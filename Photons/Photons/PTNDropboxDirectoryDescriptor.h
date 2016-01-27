// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDescriptor.h"

@class DBMetadata;

NS_ASSUME_NONNULL_BEGIN

/// Represents a Dropbox directory. This is a simple wrapper on top of \c DBMetadata.
@interface PTNDropboxDirectoryDescriptor : NSObject <PTNAlbumDescriptor>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the Dropbox metadata of the directory to be represented by this descriptor.
/// \c metadata.isDirectory must be \c YES.
- (instancetype)initWithMetadata:(DBMetadata *)metadata NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
