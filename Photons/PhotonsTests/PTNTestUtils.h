// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAlbum, LTRandomAccessCollection;

/// Creates and returns a \c PTNAlbum with \c url, \c assets and \c subalbums.
id<PTNAlbum> PTNCreateAlbum(NSURL * _Nullable url, id<LTRandomAccessCollection> _Nullable assets,
                            id<LTRandomAccessCollection> _Nullable subalbums);

NS_ASSUME_NONNULL_END
