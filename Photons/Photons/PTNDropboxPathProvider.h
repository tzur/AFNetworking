// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Factory class to supply download paths of downloaded Dropbox assets.
@protocol PTNDropboxPathProvider <NSObject>

/// Unique and consistent local path in storage for Dropbox file located at \c path with
/// revision \c revision. If the given \c revision is \c nil, the required local path is for the
/// latest revision of the file represented by \c path.
- (NSString *)localPathForFileInPath:(NSString *)path revision:(nullable NSString *)revision;

/// Unique and consistent local path in storage for the thumbnail of a Dropbox file
/// located at \c path with of size \c size. This is similar to \c localPathForFile:revision: but
/// includes variance in naming caused by \c size to prevent collisions of thumbnails with various
/// sizes.
- (NSString *)localPathForThumbnailInPath:(NSString *)path size:(CGSize)size;

@end

/// \c PTNDropboxStorageManager protocol implementation that supplies paths constructed from hashed
/// versions of given \c path and \c revision or \c path and \c size pairs, located in the
/// application's temporary folder.
@interface PTNDropboxPathProvider : NSObject <PTNDropboxPathProvider>
@end

NS_ASSUME_NONNULL_END
