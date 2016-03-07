// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUChangeset.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTUChangeset

- (instancetype)initWithBeforeDataModel:(nullable PTUDataModel *)beforeDataModel
                         afterDataModel:(PTUDataModel *)afterDataModel
                                deleted:(nullable NSArray<NSIndexPath *> *)deleted
                               inserted:(nullable NSArray<NSIndexPath *> *)inserted
                                updated:(nullable NSArray<NSIndexPath *> *)updated
                                  moved:(nullable PTUChangesetMoves *)moved {
  if (self = [super init]) {
    _beforeDataModel = beforeDataModel;
    _afterDataModel = afterDataModel;
    _insertedIndexes = inserted;
    _deletedIndexes = deleted;
    _updatedIndexes = updated;
    _movedIndexes = moved;
  }
  return self;
}

- (instancetype)initWithAfterDataModel:(PTUDataModel *)afterDataModel {
  return [self initWithBeforeDataModel:nil afterDataModel:afterDataModel deleted:nil inserted:nil
                               updated:nil moved:nil];
}

- (BOOL)hasIncrementalChanges {
  return self.deletedIndexes.count || self.insertedIndexes.count || self.updatedIndexes.count ||
      self.movedIndexes.count;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTUChangeset *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self compare:self.beforeDataModel with:object.beforeDataModel] &&
      [self.afterDataModel isEqual:object.afterDataModel] &&
      [self compare:self.insertedIndexes with:object.insertedIndexes] &&
      [self compare:self.deletedIndexes with:object.deletedIndexes] &&
      [self compare:self.updatedIndexes with:object.updatedIndexes] &&
      [self compare:self.movedIndexes with:object.movedIndexes] &&
      self.hasIncrementalChanges == object.hasIncrementalChanges;
}

- (BOOL)compare:(nullable id)first with:(nullable id)second {
  return first == second || [first isEqual:second];
}

- (NSUInteger)hash {
  return self.beforeDataModel.hash ^ self.afterDataModel.hash ^ self.insertedIndexes.hash ^
      self.deletedIndexes.hash ^ self.updatedIndexes.hash ^ self.movedIndexes.hash ^
      self.hasIncrementalChanges;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, before: %@, after: %@, removed: %@, inserted: %@, "
            "updated: %@, moved: %@>", self.class, self, self.beforeDataModel, self.afterDataModel,
            self.deletedIndexes, self.insertedIndexes, self.updatedIndexes, self.movedIndexes];
}

@end

NS_ASSUME_NONNULL_END
