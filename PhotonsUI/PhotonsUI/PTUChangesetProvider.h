// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for providers of collection view updates to conform to, enabling fetching of data and
/// if possible continuous updates to it. This protocol enables mapping of any sort of data changes
/// into a uniform object made especially for \c UICollectionView granting them the ability to
/// perform batch updates.
@protocol PTUChangesetProvider <NSObject>

/// Fetches changeset of the data backed by this provider. If supported, the signal will continue to
/// send updates as the underlying data is changed. If no such continuous updates are available the
/// signal will complete. If the fetching of updates cannot be made the signal will err with an
/// appropriate error.
///
/// @note This is a cold signal and will perform work only once subscribed to.
///
/// @return <tt>RACSignal<PTUChangeset *></tt>.
- (RACSignal *)fetchChangeset;

@end

NS_ASSUME_NONNULL_END
