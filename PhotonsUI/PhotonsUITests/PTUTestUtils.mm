// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUTestUtils.h"

#import <LTKit/LTRandomAccessCollection.h>

#import "PTUChangeset.h"
#import "PTUChangesetMove.h"

NS_ASSUME_NONNULL_BEGIN

PTUChangesetMove *PTUCreateChangesetMove(NSUInteger from, NSUInteger to, NSUInteger section) {
  NSIndexPath *fromPath = [NSIndexPath indexPathForItem:from inSection:section];
  NSIndexPath *toPath = [NSIndexPath indexPathForItem:to inSection:section];
  return [PTUChangesetMove changesetMoveFrom:fromPath to:toPath];
}

#pragma mark -
#pragma mark Semantic equality
#pragma mark -

static BOOL PTUCollectionSemanticallyEqual(id<LTRandomAccessCollection> lhs,
                                           id<LTRandomAccessCollection> rhs) {
  if (lhs == rhs) {
    return YES;
  }

  if (lhs.count != rhs.count) {
    return NO;
  }

  for (NSUInteger i = 0; i < lhs.count; ++i) {
    if (![lhs[i] isEqual:rhs[i]]) {
      return NO;
    }
  }

  return YES;
}

static BOOL PTUDataModelSemanticallyEqual(PTUDataModel * _Nullable lhs,
                                          PTUDataModel * _Nullable rhs) {
  if (lhs == rhs) {
    return YES;
  }

  if (lhs.count != rhs.count) {
    return NO;
  }

  for (NSUInteger i = 0; i < lhs.count; ++i) {
    if (!PTUCollectionSemanticallyEqual(lhs[i], rhs[i])) {
      return NO;
    }
  }

  return YES;
}

static BOOL PTUCompare(NSObject * _Nullable lhs, NSObject * _Nullable rhs) {
  return rhs == lhs || [lhs isEqual:rhs];
}

BOOL PTUChangesetSemanticallyEqual(PTUChangeset *lhs, PTUChangeset *rhs) {
  return lhs == rhs ||
      (PTUCompare(lhs.insertedIndexes, rhs.insertedIndexes) &&
       PTUCompare(lhs.deletedIndexes, rhs.deletedIndexes) &&
       PTUCompare(lhs.updatedIndexes, rhs.updatedIndexes) &&
       PTUCompare(lhs.movedIndexes, rhs.movedIndexes) &&
       PTUDataModelSemanticallyEqual(lhs.beforeDataModel, rhs.beforeDataModel) &&
       PTUDataModelSemanticallyEqual(lhs.afterDataModel, rhs.afterDataModel));
}

NS_ASSUME_NONNULL_END
