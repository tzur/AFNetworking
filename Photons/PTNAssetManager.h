// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAssetManager <NSObject>

/// Fetches the album identified by the given \c url, and continues to stream updates about the
/// album in the returned signal.
///
/// The returned signal sends \c id<PTNAlbum> objects. The signal can be infinite or contain a
/// single value, depending on the capabilities of the asset manager:
///   - If the manager is capable of observing the fetched album and reporting changes, the signal
///     will be infinite, where each value is sent upon album update.
///   - If the manager is not capable of such observation, a single \c id<PTNAlbum> value will be
///     sent upon fetch, and then the signal will complete.
///
/// If the album doesn't exist, the signal will complete with an error.
- (RACSignal *)fetchAlbumWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
