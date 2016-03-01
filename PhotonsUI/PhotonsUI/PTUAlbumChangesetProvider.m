// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUAlbumChangesetProvider.h"

#import <Photons/PTNAlbum.h>
#import <Photons/PTNAlbumChangeset.h>
#import <Photons/PTNAlbumChangesetMove.h>
#import <Photons/PTNAssetManager.h>
#import <Photons/PTNCollection.h>

#import "PTUChangeset.h"
#import "PTUChangesetMove.h"

NS_ASSUME_NONNULL_BEGIN

/// Category over \c NSIndexSet enabling its representation as an array.
@interface NSIndexSet (PhotonsUI)

/// Array with contents of this \c NSIndexSet mapped to \c NSIndexPath object with \c section in an
/// undefined order.
- (NSArray<NSIndexPath *> *)ptn_arrayWithSection:(NSInteger)section;

@end

@implementation NSIndexSet (PhotonsUI)

- (NSArray<NSIndexPath *> *)ptn_arrayWithSection:(NSInteger)section {
  return [self.rac_sequence map:^id(NSNumber *idx) {
    return [NSIndexPath indexPathForItem:idx.integerValue inSection:section];
  }].array;
}

@end

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

static const NSUInteger kAssetSection = 1;

- (RACSignal *)fetchChangeset {
  return [[self.manager fetchAlbumWithURL:self.url]
      map:^id(PTNAlbumChangeset *changeset) {
        return PTUChangesetFromAlbumChangeset(changeset);
      }];
}

static PTUChangeset *PTUChangesetFromAlbumChangeset(PTNAlbumChangeset *changeset) {
  PTUDataModel *afterData = @[changeset.afterAlbum.subalbums, changeset.afterAlbum.assets];
  if (!changeset.beforeAlbum) {
    return [[PTUChangeset alloc] initWithAfterDataModel:afterData];
  }

  PTUDataModel *beforeData = @[changeset.beforeAlbum.subalbums, changeset.beforeAlbum.assets];
  return [[PTUChangeset alloc] initWithBeforeDataModel:beforeData afterDataModel:afterData
      deleted:[changeset.removedIndexes ptn_arrayWithSection:kAssetSection]
      inserted:[changeset.insertedIndexes ptn_arrayWithSection:kAssetSection]
      updated:[changeset.updatedIndexes ptn_arrayWithSection:kAssetSection]
      moved:PTUMovesFromPTNMoves(changeset.moves)];
}

static PTUChangesetMoves *PTUMovesFromPTNMoves(PTNAlbumChangesetMoves *moves) {
  return [moves.rac_sequence map:^id(PTNAlbumChangesetMove *move) {
    NSIndexPath *from = [NSIndexPath indexPathForItem:move.fromIndex inSection:kAssetSection];
    NSIndexPath *to = [NSIndexPath indexPathForItem:move.toIndex inSection:kAssetSection];
    return [PTUChangesetMove changesetMoveFrom:from to:to];
  }].array;
}

@end

NS_ASSUME_NONNULL_END
