// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUAlbumChangesetProvider.h"

#import <Photons/PTNAlbum.h>
#import <Photons/PTNAlbumChangeset.h>
#import <Photons/PTNAlbumChangesetMove.h>
#import <Photons/PTNAssetManager.h>
#import <Photons/PTNIncrementalChanges.h>

#import "PTUChangeset.h"
#import "PTUChangesetMove.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUAlbumChangesetProvider ()

/// Asset manager to use for fetching of album.
@property (readonly, nonatomic) id<PTNAssetManager> manager;

/// URL for album that is provided by this provider.
@property (readonly, nonatomic) NSURL *url;

@end

@implementation PTUAlbumChangesetProvider

- (instancetype)initWithManager:(id<PTNAssetManager>)manager albumURL:(NSURL *)url {
  if (self = [super init]) {
    _manager = manager;
    _url = url;
  }
  return self;
}

#pragma mark -
#pragma mark PTUChangesetProvider
#pragma mark -

static const NSUInteger kAlbumSection = 0;
static const NSUInteger kAssetSection = 1;

- (RACSignal *)fetchChangeset {
  return [[self.manager fetchAlbumWithURL:self.url]
      map:^id(PTNAlbumChangeset *changeset) {
        return PTUChangesetFromAlbumChangeset(changeset);
      }];
}

static PTUChangeset *PTUChangesetFromAlbumChangeset(PTNAlbumChangeset *changeset) {
  PTUDataModel *afterData = @[changeset.afterAlbum.subalbums, changeset.afterAlbum.assets];
  if (!changeset.subalbumChanges && !changeset.assetChanges) {
    return [[PTUChangeset alloc] initWithAfterDataModel:afterData];
  }

  PTUDataModel *beforeData = @[changeset.beforeAlbum.subalbums, changeset.beforeAlbum.assets];
  NSArray *deleted = PTUIndexPathArray(changeset.subalbumChanges.removedIndexes,
                                       changeset.assetChanges.removedIndexes);
  NSArray *inserted = PTUIndexPathArray(changeset.subalbumChanges.insertedIndexes,
                                        changeset.assetChanges.insertedIndexes);
  NSArray *updated = PTUIndexPathArray(changeset.subalbumChanges.updatedIndexes,
                                       changeset.assetChanges.updatedIndexes);
  NSArray *moved = PTUMovesIndexPathArray(changeset.subalbumChanges.moves,
                                          changeset.assetChanges.moves);

  return [[PTUChangeset alloc] initWithBeforeDataModel:beforeData afterDataModel:afterData
                                               deleted:deleted inserted:inserted updated:updated
                                                 moved:moved];
}

#pragma mark -
#pragma mark Changeset mapping
#pragma mark -

static NSArray *PTUIndexPathArray(NSIndexSet * _Nullable albumIndexSet,
                                  NSIndexSet * _Nullable assetIndexSet) {
  NSArray *albumArray = PTUArrayWithSection(albumIndexSet, kAlbumSection) ?: @[];
  NSArray *assetArray = PTUArrayWithSection(assetIndexSet, kAssetSection) ?: @[];

  return [albumArray arrayByAddingObjectsFromArray:assetArray];
}

static PTUChangesetMoves *PTUMovesIndexPathArray(PTNAlbumChangesetMoves *albumMoves,
                                                 PTNAlbumChangesetMoves *assetMoves) {
  NSArray *albumArray = PTUMovesWithSection(albumMoves, kAlbumSection) ?: @[];
  NSArray *assetArray = PTUMovesWithSection(assetMoves, kAssetSection) ?: @[];

  return [albumArray arrayByAddingObjectsFromArray:assetArray];
}

#pragma mark -
#pragma mark Index path section
#pragma mark -

static NSArray * _Nullable PTUArrayWithSection(NSIndexSet * _Nullable indexSet,
                                               NSUInteger section) {
  return [indexSet.rac_sequence map:^id(NSNumber *idx) {
    return [NSIndexPath indexPathForItem:idx.integerValue inSection:section];
  }].array;
}

static NSArray * _Nullable PTUMovesWithSection(PTNAlbumChangesetMoves * _Nullable moves,
                                               NSUInteger section) {
  return [moves.rac_sequence map:^id(PTNAlbumChangesetMove *move) {
    NSIndexPath *from = [NSIndexPath indexPathForItem:move.fromIndex inSection:section];
    NSIndexPath *to = [NSIndexPath indexPathForItem:move.toIndex inSection:section];
    return [PTUChangesetMove changesetMoveFrom:from to:to];
  }].array;
}

@end

NS_ASSUME_NONNULL_END
