// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNIncrementalChanges.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNIncrementalChanges

+ (instancetype)changesWithRemovedIndexes:(nullable NSIndexSet *)removedIndexes
                          insertedIndexes:(nullable NSIndexSet *)insertedIndexes
                           updatedIndexes:(nullable NSIndexSet *)updatedIndexes
                                    moves:(nullable PTNAlbumChangesetMoves *)moves {
  PTNIncrementalChanges *changes = [[PTNIncrementalChanges alloc] init];
  changes->_removedIndexes = removedIndexes;
  changes->_insertedIndexes = insertedIndexes;
  changes->_updatedIndexes = updatedIndexes;
  changes->_moves = moves;
  return changes;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNIncrementalChanges *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self compare:self.removedIndexes with:object.removedIndexes] &&
      [self compare:self.insertedIndexes with:object.insertedIndexes] &&
      [self compare:self.updatedIndexes with:object.updatedIndexes] &&
      [self compare:self.moves with:object.moves];
}

- (BOOL)compare:(nullable id)first with:(nullable id)second {
  return first == second || [first isEqual:second];
}

- (NSUInteger)hash {
  return [self.removedIndexes hash] ^ [self.insertedIndexes hash] ^ [self.updatedIndexes hash] ^
      [self.moves hash];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, removed: %@, inserted: %@, updated: %@, "
          "moved: %@>", self.class, self, self.removedIndexes, self.insertedIndexes,
          self.updatedIndexes, self.moves];
}

@end

NS_ASSUME_NONNULL_END
