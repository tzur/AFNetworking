// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNAlbumChangeset.h"

#import "PTNAlbum.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNAlbumChangeset

+ (instancetype)changesetWithAfterAlbum:(id<PTNAlbum>)afterAlbum {
  PTNAlbumChangeset *changeset = [[PTNAlbumChangeset alloc] init];
  changeset->_afterAlbum = afterAlbum;
  return changeset;
}

+ (instancetype)changesetWithBeforeAlbum:(nullable id<PTNAlbum>)beforeAlbum
                              afterAlbum:(id<PTNAlbum>)afterAlbum
                          removedIndexes:(nullable NSIndexSet *)removedIndexes
                         insertedIndexes:(nullable NSIndexSet *)insertedIndexes
                          updatedIndexes:(nullable NSIndexSet *)updatedIndexes
                                   moves:(nullable PTNAlbumChangesetMoves *)moves {
  PTNAlbumChangeset *changeset = [[PTNAlbumChangeset alloc] init];
  changeset->_beforeAlbum = beforeAlbum;
  changeset->_afterAlbum = afterAlbum;
  changeset->_removedIndexes = removedIndexes;
  changeset->_insertedIndexes = insertedIndexes;
  changeset->_updatedIndexes = updatedIndexes;
  changeset->_moves = moves;
  return changeset;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNAlbumChangeset *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self compare:self.beforeAlbum with:object.beforeAlbum] &&
      [self compare:self.afterAlbum with:object.afterAlbum] &&
      [self compare:self.removedIndexes with:object.removedIndexes] &&
      [self compare:self.insertedIndexes with:object.insertedIndexes] &&
      [self compare:self.updatedIndexes with:object.updatedIndexes] &&
      [self compare:self.moves with:object.moves];
}

- (BOOL)compare:(nullable id)first with:(nullable id)second {
  return first == second || [first isEqual:second];
}

- (NSUInteger)hash {
  return [self.beforeAlbum hash] ^ [self.afterAlbum hash] ^ [self.removedIndexes hash] ^
      [self.insertedIndexes hash] ^ [self.updatedIndexes hash] ^ [self.moves hash];
}

- (NSString *)description {
  if (self.beforeAlbum) {
    return [NSString stringWithFormat:@"<%@: %p, before: %@, after: %@, removed: %@, inserted: %@, "
            "updated: %@, moved: %@>", self.class, self, self.beforeAlbum, self.afterAlbum,
            self.removedIndexes, self.insertedIndexes, self.updatedIndexes, self.moves];
  } else {
    return [NSString stringWithFormat:@"<%@: %p, album: %@>", self.class, self, self.afterAlbum];
  }
}

@end

NS_ASSUME_NONNULL_END
