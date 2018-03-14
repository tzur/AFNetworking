// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUCompoundChangesetProvider.h"

#import <Photons/RACSignal+Photons.h>

#import "PTUChangeset.h"
#import "PTUChangesetMove.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUCompoundChangesetProvider ()

/// Underlying list of the changeset providers concatenated by this provider.
@property (readonly, nonatomic) NSArray<id<PTUChangesetProvider>> *changesetProviders;

/// Static metadata returned by this provider.
@property (readonly, nonatomic) PTUChangesetMetadata *changesetMetadata;

@end

@implementation PTUCompoundChangesetProvider

- (instancetype)initWithChangesetProviders:(NSArray<id<PTUChangesetProvider>> *)changesetProviders
                         changesetMetadata:(PTUChangesetMetadata *)changesetMetadata {
  if (self = [super init]) {
    _changesetProviders = changesetProviders;
    _changesetMetadata = changesetMetadata;
  }
  return self;
}

#pragma mark -
#pragma mark PTUChangesetProvider
#pragma mark -

- (RACSignal *)fetchChangesetMetadata {
  return [RACSignal return:self.changesetMetadata];
}

- (RACSignal *)fetchChangeset {
  return [self combinedChangesetProviders];
}

- (RACSignal *)combinedChangesetProviders {
  NSArray<RACSignal *> *changesetSignalsStartEmpty = [self.changesetProviders.rac_sequence
      map:^RACSignal *(id<PTUChangesetProvider> provider) {
        return [[provider fetchChangeset]
            startWith:[[PTUChangeset alloc] initWithAfterDataModel:@[]]];
      }].array;

  return [self combinedDataSignals:changesetSignalsStartEmpty];
}

- (RACSignal *)combinedDataSignals:(NSArray<RACSignal *> *)dataSignals {
  return [[RACSignal
      ptn_combineLatestWithIndex:dataSignals]
      map:^PTUChangeset *(RACTuple *changesetsWithIndex) {
        RACTupleUnpack(NSArray<PTUChangeset *> *changesets,
                       NSNumber *changeIndex) = changesetsWithIndex;

        NSMutableArray *beforeDataModel = [NSMutableArray array];
        NSMutableArray *afterDataModel = [NSMutableArray array];
        NSMutableArray *deleted = [NSMutableArray array];
        NSMutableArray *inserted = [NSMutableArray array];
        NSMutableArray *updated = [NSMutableArray array];
        NSMutableArray *moved = [NSMutableArray array];

        for (NSUInteger i = 0; i < changesets.count; ++i) {
          PTUChangeset *changeset = changesets[i];
          if (changeIndex && changeIndex.unsignedIntegerValue == i) {
            NSUInteger afterOffset = afterDataModel.count;
            NSUInteger beforeOffset = beforeDataModel.count;

            [beforeDataModel addObjectsFromArray:changeset.beforeDataModel ?: @[]];
            [afterDataModel addObjectsFromArray:changeset.afterDataModel];

            [deleted addObjectsFromArray:
                PTUIndexPathsWithSectionOffset(changeset.deletedIndexes, beforeOffset) ?: @[]];
            [inserted addObjectsFromArray:
                PTUIndexPathsWithSectionOffset(changeset.insertedIndexes, beforeOffset) ?: @[]];
            [updated addObjectsFromArray:
                PTUIndexPathsWithSectionOffset(changeset.updatedIndexes, beforeOffset) ?: @[]];
            [moved addObjectsFromArray:
                PTUMovesWithSectionOffset(changeset.movedIndexes, afterOffset) ?: @[]];
          } else {
            [beforeDataModel addObjectsFromArray:changeset.afterDataModel];
            [afterDataModel addObjectsFromArray:changeset.afterDataModel];
          }
        }

        return [[PTUChangeset alloc]
                initWithBeforeDataModel:changeIndex ? beforeDataModel : nil
                afterDataModel:afterDataModel
                deleted:deleted.count ? deleted : nil
                inserted:inserted.count ? inserted : nil
                updated:updated.count ? updated : nil
                moved:moved.count ? moved : nil];
      }];
}

#pragma mark -
#pragma mark Section mapping
#pragma mark -

static NSArray<NSIndexPath *> * _Nullable PTUIndexPathsWithSectionOffset
    (NSArray<NSIndexPath *> * _Nullable indexPaths, NSUInteger sectionOffset) {
  if (!indexPaths) {
    return nil;
  }

  return [indexPaths.rac_sequence map:^id(NSIndexPath *indexPath) {
    return [NSIndexPath indexPathForItem:indexPath.item
                               inSection:indexPath.section + sectionOffset];
  }].array;
}

static PTUChangesetMoves * _Nullable PTUMovesWithSectionOffset(PTUChangesetMoves * _Nullable moves,
                                                               NSUInteger sectionOffset) {
  if (!moves) {
    return nil;
  }

  return [moves.rac_sequence map:^id(PTUChangesetMove *move) {
    NSIndexPath *from = [NSIndexPath indexPathForItem:move.fromIndex.item
                                            inSection:move.fromIndex.section + sectionOffset];
    NSIndexPath *to = [NSIndexPath indexPathForItem:move.toIndex.item
                                          inSection:move.toIndex.section + sectionOffset];
    return [PTUChangesetMove changesetMoveFrom:from to:to];
  }].array;
}

@end

NS_ASSUME_NONNULL_END
