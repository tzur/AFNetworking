// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSIndexPath+Blueprints.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSIndexPath (Blueprints)

+ (instancetype)blu_indexPathWithIndexes:(const std::vector<NSUInteger> &)indexes {
  if (indexes.size()) {
    return [self indexPathWithIndexes:indexes.data() length:indexes.size()];
  } else {
    return [self blu_empty];
  }
}

+ (instancetype)blu_empty {
  static NSIndexPath *indexPath;

  // Since -[NSIndexPath init] is deprecated, a more complex but documented method for creating an
  // empty index path is taken - create an index path with an item and remove it. From
  // \c indexPathByRemovingLastIndex discussion: "Returns an empty NSIndexPath instance if the
  // receiving index path’s length is 1 or less."
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    indexPath = [[NSIndexPath indexPathWithIndex:0] indexPathByRemovingLastIndex];
  });

  return indexPath;
}

- (NSIndexPath *)blu_indexPathByAddingIndexPath:(NSIndexPath *)indexPath {
  std::vector<NSUInteger> indexes(self.length + indexPath.length);
  if (self.length) {
    [self getIndexes:&indexes[0] range:NSMakeRange(0, self.length)];
  }
  if (indexPath.length) {
    [indexPath getIndexes:&indexes[self.length] range:NSMakeRange(0, indexPath.length)];
  }
  return [NSIndexPath blu_indexPathWithIndexes:indexes];
}

- (std::vector<NSUInteger>)blu_indexes {
  std::vector<NSUInteger> indexes(self.length);
  if (self.length) {
    [self getIndexes:indexes.data() range:NSMakeRange(0, indexes.size())];
  }
  return indexes;
}

@end

NS_ASSUME_NONNULL_END
