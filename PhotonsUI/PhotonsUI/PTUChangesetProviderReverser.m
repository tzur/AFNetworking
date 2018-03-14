// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUChangesetProviderReverser.h"

#import <LTKit/NSArray+Functional.h>

#import "PTUChangeset.h"
#import "PTUChangesetMove.h"
#import "PTUReversedRandomAccessCollection.h"

NS_ASSUME_NONNULL_BEGIN

/// Category over \c NSIndexSet provider convenient initializer for a complete set.
@interface NSIndexSet (PTUChangesetProviderReverser)

/// An index set with all indexes in range <tt>[0, NSNotFound - 1]</tt>.
+ (instancetype)ptu_completeIndexSet;

@end

@implementation NSIndexSet (PTUChangesetProviderReverser)

+ (instancetype)ptu_completeIndexSet {
  return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, NSNotFound - 1)];
}

@end

@interface PTUChangesetProviderReverser ()

/// Underlying provider.
@property (readonly, nonatomic) id<PTUChangesetProvider> provider;

/// Sections to reverse.
@property (readonly, nonatomic, nullable) NSIndexSet *sectionsToReverese;

@end

@implementation PTUChangesetProviderReverser

- (instancetype)initWithProvider:(id<PTUChangesetProvider>)provider
               sectionsToReverse:(NSIndexSet *)sectionsToReverse {
  if (self = [super init]) {
    _provider = provider;
    _sectionsToReverese = sectionsToReverse;
  }
  return self;
}

- (instancetype)initWithProvider:(id<PTUChangesetProvider>)provider {
  return [self initWithProvider:provider sectionsToReverse:[NSIndexSet ptu_completeIndexSet]];
}

#pragma mark -
#pragma mark PTUChangesetProvider
#pragma mark -

- (RACSignal *)fetchChangeset {
  return [[self.provider fetchChangeset] map:^PTUChangeset *(PTUChangeset *changeset) {
    return [self reverseChangeset:changeset];
  }];
}

- (RACSignal *)fetchChangesetMetadata {
  return [self.provider fetchChangesetMetadata];
}

#pragma mark -
#pragma mark Reversing
#pragma mark -

- (PTUChangeset *)reverseChangeset:(PTUChangeset *)changeset {
  PTUDataModel *before = [self reverseDataModel:changeset.beforeDataModel];
  PTUDataModel *after = [self reverseDataModel:changeset.afterDataModel];

  NSArray *beforeSectionSizes = [self sectionSizes:changeset.beforeDataModel];
  NSArray *afterSectionSizes = [self sectionSizes:changeset.afterDataModel];

  NSArray *deleted = [self reverseIndexPaths:changeset.deletedIndexes
                                sectionSizes:beforeSectionSizes];
  NSArray *inserted = [self reverseIndexPaths:changeset.insertedIndexes
                                 sectionSizes:afterSectionSizes];
  NSArray *updated = [self reverseIndexPaths:changeset.updatedIndexes
                                sectionSizes:afterSectionSizes];
  NSArray *moves = [self reverseMoves:changeset.movedIndexes beforeSectionSizes:beforeSectionSizes
                    afterSectionSizes:afterSectionSizes];

  return [[PTUChangeset alloc] initWithBeforeDataModel:before afterDataModel:after deleted:deleted
                                              inserted:inserted updated:updated moved:moves];
}

- (NSArray<NSNumber *> *)sectionSizes:(PTUDataModel * _Nullable)dataModel {
  if (!dataModel) {
    return @[];
  }

  return [dataModel lt_map:^NSNumber *(NSArray *section) {
    return @(section.count);
  }];
}

- (nullable PTUDataModel *)reverseDataModel:(nullable PTUDataModel *)dataModel {
  if (!dataModel) {
    return nil;
  }

  NSMutableArray *reversedDataModel = [NSMutableArray array];

  for (NSUInteger section = 0; section < dataModel.count; ++section) {
    id<LTRandomAccessCollection> newSection = [self shouldReverseSection:section] ?
        [[PTUReversedRandomAccessCollection alloc] initWithCollection:dataModel[section]] :
        dataModel[section];

    [reversedDataModel addObject:newSection];
  }

  return reversedDataModel;
}

- (nullable NSArray<NSIndexPath *> *)reverseIndexPaths:(nullable NSArray<NSIndexPath *> *)indexPaths
                                          sectionSizes:(NSArray<NSNumber *> *)sectionSizes {
  if (!indexPaths) {
    return nil;
  }

  return [indexPaths lt_map:^NSIndexPath *(NSIndexPath *indexPath) {
      return [self reverseIndexPath:indexPath
                    withSectionSize:sectionSizes[indexPath.section].unsignedIntegerValue];
    }];
}

- (nullable PTUChangesetMoves *)reverseMoves:(nullable PTUChangesetMoves *)moves
                          beforeSectionSizes:(NSArray<NSNumber *> *)beforeSectionSizes
                           afterSectionSizes:(NSArray<NSNumber *> *)afterSectionSizes {
  if (!moves) {
    return nil;
  }

  return [moves lt_map:^PTUChangesetMove *(PTUChangesetMove *move) {
    NSIndexPath *reversedFrom = [self reverseIndexPath:move.fromIndex
        withSectionSize:beforeSectionSizes[move.fromIndex.section].unsignedIntegerValue];
    NSIndexPath *reversedTo = [self reverseIndexPath:move.toIndex
        withSectionSize:afterSectionSizes[move.toIndex.section].unsignedIntegerValue];

    return [PTUChangesetMove changesetMoveFrom:reversedFrom to:reversedTo];
  }];
}

- (NSIndexPath *)reverseIndexPath:(NSIndexPath *)indexPath withSectionSize:(NSUInteger)sectionSize {
  if (![self shouldReverseSection:indexPath.section]) {
    return indexPath;
  }

  NSInteger reversedItem = sectionSize - indexPath.item - 1;
  return [NSIndexPath indexPathForItem:reversedItem inSection:indexPath.section];
}

- (BOOL)shouldReverseSection:(NSInteger)section {
  return !self.sectionsToReverese || [self.sectionsToReverese containsIndex:section];
}

@end

NS_ASSUME_NONNULL_END
