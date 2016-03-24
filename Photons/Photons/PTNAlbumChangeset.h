// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAlbum;

@class PTNIncrementalChanges;

/// Value class encapsulating the changes between two \c id<PTNAlbum> instances, \c beforeAlbum and
/// \c afterAlbum. The changes, if available, describe how to perform modifications to
/// \c beforeAlbum in order to produce \c afterAlbum.
@interface PTNAlbumChangeset : NSObject

/// Creates a null changeset with \c afterAlbum and \c nil beforeAlbum, indicating no changes are
/// available for this album.
+ (instancetype)changesetWithAfterAlbum:(id<PTNAlbum>)afterAlbum;

/// Constructs a new \c PTNAlbumChangeset object with \c beforeAlbum as the album before changes,
/// \c afterAlbum as the album after changes, and \c subalbumChanges and \c assetChanges as
/// incremental changes to subalbums and assets respectively, if available.
+ (instancetype)changesetWithBeforeAlbum:(nullable id<PTNAlbum>)beforeAlbum
                              afterAlbum:(id<PTNAlbum>)afterAlbum
                         subalbumChanges:(nullable PTNIncrementalChanges *)subalbumChanges
                            assetChanges:(nullable PTNIncrementalChanges *)assetChanges;

/// Album before the changes, or \c nil if previous album is available.
@property (readonly, nonatomic, nullable) id<PTNAlbum> beforeAlbum;

/// Album after the changes.
@property (readonly, nonatomic) id<PTNAlbum> afterAlbum;

/// Incremental changes to subalbums or \c nil if no incremental changes to subalbums are available.
@property (readonly, nonatomic, nullable) PTNIncrementalChanges *subalbumChanges;

/// Incremental changes to assets or \c nil if no incremental changes to assets are available.
@property (readonly, nonatomic, nullable) PTNIncrementalChanges *assetChanges;

@end

NS_ASSUME_NONNULL_END
