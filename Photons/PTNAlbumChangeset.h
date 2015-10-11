// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAlbum;

@class PTNAlbumChangesetMove;

typedef NSArray<PTNAlbumChangesetMove *> PTNAlbumChangesetMoves;

/// Value class encapsulating the changes between two \c id<PATNAlbum> instances, \c beforeAlbum and
/// \c afterAlbum. The changes describe how to perform modifications to \c beforeAlbum in order to
/// produce \c afterAlbum. The changes need to be applied in the following order:
///
/// 1. Remove items at the indexes specified by the \c removedIndexes property.
///
/// 2. Insert items at the indexes specified by the \c insertedIndexes property.
///
/// 3. Update items specified by the \c updatedIndexes property.
///
/// 4. Iterate over the \c moves array in order and handle items whose locations have changed.
@interface PTNAlbumChangeset : NSObject

/// Creates a null changeset with \c afterAlbum and \c nil beforeAlbum, indicating no changes are
/// available for this album.
+ (instancetype)changesetWithAfterAlbum:(id<PTNAlbum>)afterAlbum;

/// Constructs a new \c PTNAlbumChangeset object with all the required properties.
+ (instancetype)changesetWithBeforeAlbum:(nullable id<PTNAlbum>)beforeAlbum
                              afterAlbum:(id<PTNAlbum>)afterAlbum
                          removedIndexes:(nullable NSIndexSet *)removedIndexes
                         insertedIndexes:(nullable NSIndexSet *)insertedIndexes
                          updatedIndexes:(nullable NSIndexSet *)updatedIndexes
                                   moves:(nullable PTNAlbumChangesetMoves *)moves;

/// Album before the changes, or \c nil if previous album is available.
@property (readonly, nonatomic, nullable) id<PTNAlbum> beforeAlbum;

/// Album after the changes.
@property (readonly, nonatomic) id<PTNAlbum> afterAlbum;

/// Indexes of objects that were removed, or \c nil if no indexes are available.
@property (readonly, nonatomic, nullable) NSIndexSet *removedIndexes;

/// Indexes of objects that were inserted, or \c nil if no indexes are available.
@property (readonly, nonatomic, nullable) NSIndexSet *insertedIndexes;

/// Indexes of objects that were updated, or \c nil if no indexes are available.
@property (readonly, nonatomic, nullable) NSIndexSet *updatedIndexes;

/// Array of \c PTNAlbumChangesetMove objects, or \c nil if no moves are available.
@property (readonly, nonatomic, nullable) PTNAlbumChangesetMoves *moves;

@end

NS_ASSUME_NONNULL_END
