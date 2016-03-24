// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@class PTNAlbumChangesetMove;

typedef NSArray<PTNAlbumChangesetMove *> PTNAlbumChangesetMoves;

/// Value class representing the changes between two \c id<PTNAlbum> instances. The changes describe
/// how to perform modifications to the first album in order to produce the latter. The changes need
/// to be applied in the following order:
///
/// 1. Remove items at the indexes specified by the \c removedIndexes property.
///
/// 2. Insert items at the indexes specified by the \c insertedIndexes property.
///
/// 3. Update items specified by the \c updatedIndexes property.
///
/// 4. Iterate over the \c moves array in order and handle items whose locations have changed.
@interface PTNIncrementalChanges : NSObject

/// Constructs a new \c PTNIncrementalChanges object with given \c removedIndexes,
/// \c insertedIndexes, \c updatedIndexes and \c moves as the indexes of the objects that were
/// changed.
+ (instancetype)changesWithRemovedIndexes:(nullable NSIndexSet *)removedIndexes
                          insertedIndexes:(nullable NSIndexSet *)insertedIndexes
                           updatedIndexes:(nullable NSIndexSet *)updatedIndexes
                                    moves:(nullable PTNAlbumChangesetMoves *)moves;

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
