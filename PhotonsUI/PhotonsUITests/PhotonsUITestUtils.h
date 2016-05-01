// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@class PTUChangesetMove;

@protocol LTRandomAccessCollection, PTNAlbum;

/// Constructs a \c PTUCollectionViewChangesetMove from <tt>(from, section)</tt> to
/// <tt>(to, section)</tt>.
PTUChangesetMove *PTUCreateChangesetMove(NSUInteger from, NSUInteger to, NSUInteger section);

/// Creates and returns a \c PTNAlbum with \c url, \c assets and \c subalbums.
id<PTNAlbum> PTNCreateAlbum(NSURL * _Nullable url, id<LTRandomAccessCollection> _Nullable assets,
                            id<LTRandomAccessCollection> _Nullable subalbums);

NS_ASSUME_NONNULL_END
