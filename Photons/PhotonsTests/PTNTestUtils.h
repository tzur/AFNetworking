// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAlbum, PTNCollection;

/// Creates and returns a \c PTNAlbum with \c url, \c assets and \c subalbums.
id<PTNAlbum> PTNCreateAlbum(NSURL * _Nullable url, id<PTNCollection> _Nullable assets,
                            id<PTNCollection> _Nullable subalbums);

NS_ASSUME_NONNULL_END
