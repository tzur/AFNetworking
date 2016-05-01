// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

@class PTUChangesetMove;

@protocol LTRandomAccessCollection;

NS_ASSUME_NONNULL_BEGIN

/// Array of \c LTRandomAccessCollection each representing a section in the data source, together
/// forming the all of the sections in the data source.
typedef NSArray<id<LTRandomAccessCollection>> PTUDataModel;

/// Dictionary of moved indexes mapping \c from index to \c to index.
typedef NSArray<PTUChangesetMove *> PTUChangesetMoves;

/// Value class encapsulating all information required to update a collection view.
@interface PTUChangeset : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c beforeDataModel representing the state before the change, \c afterDataModel
/// representing the current state after the change and \c deleted indexes, \c inserted indexes,
/// \c updated indexes and \c moved representing incremental changes from \c beforeData to
/// \c afterData. If \c deleted, \c inserted, \c updated or \c moved are \c nil it means that
/// there are no deleted, inserted, updated or moved indexes in this changeset respectively, or that
/// the changes in this changeset cannot be presented incerementally.
- (instancetype)initWithBeforeDataModel:(nullable PTUDataModel *)beforeDataModel
                         afterDataModel:(PTUDataModel *)afterDataModel
                                deleted:(nullable NSArray<NSIndexPath *> *)deleted
                               inserted:(nullable NSArray<NSIndexPath *> *)inserted
                                updated:(nullable NSArray<NSIndexPath *> *)updated
                                  moved:(nullable PTUChangesetMoves *)moved
    NS_DESIGNATED_INITIALIZER;

/// Initializes with \c afterDataModel and no incremental changes. This is equivalent to calling
/// <tt>-[initWithBeforeData:nil afterData:data deleted:nil inserted:nil updated:nil moved:nil]</tt>.
///
/// @see -initWithBeforeData:afterData:deleted:inserted:updated:moved:.
- (instancetype)initWithAfterDataModel:(PTUDataModel *)afterDataModel;

/// Array of \c LTRandomAccessCollection objects, each representing a section in the collection
/// view, and together forming all of the sections as they were before the changes in this
/// changeset.
@property (readonly, nonatomic, nullable) PTUDataModel *beforeDataModel;

/// Array of \c LTRandomAccessCollection objects, each representing a section in the collection
/// view, and together forming all of the sections as they are currently, after the changes in this
/// changeset.
@property (readonly, nonatomic) PTUDataModel *afterDataModel;

/// \c YES if this update contains changes that can be made incrementally or \c NO the updates in
/// this object cannot be represented in an incremental manner. This property is being deferred from
/// other properties and is \c YES only if there are indexes that were deleted, inserted, updated or
/// moved.
@property (readonly, nonatomic) BOOL hasIncrementalChanges;

/// Array of deleted indexes.
@property (readonly, nonatomic, nullable) NSArray<NSIndexPath *> *deletedIndexes;

/// Array of inserted indexes.
@property (readonly, nonatomic, nullable) NSArray<NSIndexPath *> *insertedIndexes;

/// Array of updated indexes.
@property (readonly, nonatomic, nullable) NSArray<NSIndexPath *> *updatedIndexes;

/// Array of \c PTUChangesetMove objects representing moved indexes in the changeset.
@property (readonly, nonatomic, nullable) PTUChangesetMoves *movedIndexes;

@end

NS_ASSUME_NONNULL_END
