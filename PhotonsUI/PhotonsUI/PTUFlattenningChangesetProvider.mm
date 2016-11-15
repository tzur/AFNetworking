// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUFlattenningChangesetProvider.h"

#import <LTKit/LTCompoundRandomAccessCollection.h>

#import "PTUChangeset.h"
#import "PTUChangesetMove.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUFlattenningChangesetProvider ()

/// Underlying changeset provider.
@property (readonly, nonatomic) id<PTUChangesetProvider> changesetProvider;

@end

@implementation PTUFlattenningChangesetProvider

- (instancetype)initWithChangesetProvider:(id<PTUChangesetProvider>)changesetProvider {
  if (self = [super init]) {
    _changesetProvider = changesetProvider;
  }
  return self;
}

#pragma mark -
#pragma mark PTUChangesetProvider
#pragma mark -

- (RACSignal *)fetchChangesetMetadata {
  return [self.changesetProvider fetchChangesetMetadata];
}

- (RACSignal *)fetchChangeset {
  return [[self.changesetProvider fetchChangeset] map:^PTUChangeset *(PTUChangeset *changeset) {
    return PTUFlattenedChangeset(changeset);
  }];
}

#pragma mark -
#pragma mark Section flattening
#pragma mark -

static PTUChangeset *PTUFlattenedChangeset(PTUChangeset *changeset) {
  NSArray<NSNumber *> *itemsUpToSection = PTUItemsUpToSection(changeset.beforeDataModel);

  return [[PTUChangeset alloc]
          initWithBeforeDataModel:PTUFlattenedDataModel(changeset.beforeDataModel)
          afterDataModel:PTUFlattenedDataModel(changeset.afterDataModel)
          deleted:PTUIndexPathsWithFlattenedOffset(changeset.deletedIndexes, itemsUpToSection)
          inserted:PTUIndexPathsWithFlattenedOffset(changeset.insertedIndexes, itemsUpToSection)
          updated:PTUIndexPathsWithFlattenedOffset(changeset.updatedIndexes, itemsUpToSection)
          moved:PTUMovesWithFlattenedOffset(changeset.movedIndexes, itemsUpToSection)];
}

static PTUDataModel * _Nullable PTUFlattenedDataModel(PTUDataModel * _Nullable dataModel) {
  if (!dataModel) {
    return nil;
  }

  if (!dataModel.count) {
    return @[];
  }

  return @[[[LTCompoundRandomAccessCollection alloc] initWithCollections:dataModel]];
}

static NSArray<NSNumber *> *PTUItemsUpToSection(PTUDataModel * _Nullable dataModel) {
  if (!dataModel) {
    return @[];
  }

  return [[dataModel.rac_sequence
      map:^NSNumber *(NSArray *section) {
        return @(section.count);
      }]
      scanWithStart:@0 reduce:^NSNumber *(NSNumber *running, NSNumber *next) {
        return @(running.unsignedIntegerValue + next.unsignedIntegerValue);
      }].array;
}

static NSArray<NSIndexPath *> * _Nullable PTUIndexPathsWithFlattenedOffset
    (NSArray<NSIndexPath *> * _Nullable indexPaths, NSArray<NSNumber *> *itemsUpToSection) {
  if (!indexPaths) {
    return nil;
  }

  return [indexPaths.rac_sequence map:^NSIndexPath *(NSIndexPath *indexPath) {
    NSUInteger flattendOffset = indexPath.section > 0 ?
        itemsUpToSection[indexPath.section - 1].unsignedIntegerValue : 0;
    return [NSIndexPath indexPathForItem:flattendOffset + indexPath.item
                               inSection:0];
  }].array;
}

static PTUChangesetMoves * _Nullable PTUMovesWithFlattenedOffset
    (PTUChangesetMoves * _Nullable moves, NSArray<NSNumber *> *itemsUpToSection) {
  if (!moves) {
    return nil;
  }
  
  return [moves.rac_sequence map:^PTUChangesetMove *(PTUChangesetMove *move) {
    NSUInteger flattendFromOffset = move.fromIndex.section > 0 ?
        itemsUpToSection[move.fromIndex.section - 1].unsignedIntegerValue : 0;
    NSUInteger flattendToOffset = move.toIndex.section > 0 ?
        itemsUpToSection[move.toIndex.section - 1].unsignedIntegerValue : 0;

    NSIndexPath *from = [NSIndexPath indexPathForItem:flattendFromOffset + move.fromIndex.item
                                            inSection:0];
    NSIndexPath *to = [NSIndexPath indexPathForItem:flattendToOffset + move.toIndex.item
                                          inSection:0];
    return [PTUChangesetMove changesetMoveFrom:from to:to];
  }].array;
}

@end

NS_ASSUME_NONNULL_END
