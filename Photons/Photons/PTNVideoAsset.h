// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a video or audio asset, enabling fetching of the asset's \c AVAsset.
@protocol PTNVideoAsset <NSObject>

/// Fetches the \c AVAsset backed by this asset. The returned signal sends a single \c AVAsset
/// object on an arbitrary thread, and completes. If the image cannot be fetched the signal errs
/// instead.
///
/// @return <tt>RACSignal<AVAsset *></tt>.
- (RACSignal *)fetchAVAsset;

@end

NS_ASSUME_NONNULL_END
