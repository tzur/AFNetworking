// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSIndexPath+Blueprints.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSIndexPath (Blueprints)

+ (instancetype)blu_indexPathWithIndexes:(const std::vector<NSUInteger> &)indexes {
  if (indexes.size()) {
    return [self indexPathWithIndexes:&indexes[0] length:indexes.size()];
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

@end

NS_ASSUME_NONNULL_END
