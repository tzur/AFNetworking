// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSArray+BLUNodeCollection.h"

#import "BLUNode.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSArray (BLUNodeCollection)

- (instancetype)blu_nodeCollectionByRemovingNodes:(NSArray<BLUNode *> *)nodes {
  NSMutableArray *mutableCollection = [self mutableCopy];
  [mutableCollection removeObjectsInArray:nodes];
  return [mutableCollection copy];
}

- (instancetype)blu_nodeCollectionByInsertingNode:(BLUNode *)node atIndex:(NSUInteger)index {
  LTParameterAssert(index <= self.count, @"Trying to insert node to index %lu which is not in the "
                    "valid range [0..%lu]", (unsigned long)index, (unsigned long)self.count);
  NSMutableArray *mutableCollection = [self mutableCopy];
  [mutableCollection insertObject:node atIndex:index];
  return [mutableCollection copy];
}

- (instancetype)blu_nodeCollectionByReplacingNodesAtIndexes:(NSIndexSet *)indexes
                                                  withNodes:(NSArray<BLUNode *> *)nodes {
  LTParameterAssert(indexes.count == nodes.count, @"Length of indexes (%lu) is not equal to the "
                    "number of nodes to replace (%lu)", (unsigned long)indexes.count,
                    (unsigned long)nodes.count);
  NSMutableArray *mutableCollection = [self mutableCopy];
  [mutableCollection replaceObjectsAtIndexes:indexes withObjects:nodes];
  return [mutableCollection copy];
}

- (nullable BLUNode *)blu_nodeForName:(NSString *)name {
  NSUInteger index = [self indexOfObjectPassingTest:^BOOL(BLUNode *obj, NSUInteger, BOOL *) {
    return [obj isKindOfClass:BLUNode.class] && [obj.name isEqualToString:name];
  }];

  if (index == NSNotFound) {
    return nil;
  }

  return self[index];
}

@end

NS_ASSUME_NONNULL_END
