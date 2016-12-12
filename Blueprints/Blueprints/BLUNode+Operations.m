// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode+Operations.h"

#import "BLUNodeCollection.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BLUNode (Operations)

- (instancetype)nodeByRemovingChildNodes:(NSArray<BLUNode *> *)nodes {
  id<BLUNodeCollection> childNodes = [self.childNodes blu_nodeCollectionByRemovingNodes:nodes];
  return [BLUNode nodeWithName:self.name childNodes:childNodes value:self.value];
}

- (instancetype)nodeByInsertingChildNode:(BLUNode *)node atIndex:(NSUInteger)index {
  id<BLUNodeCollection> childNodes = [self.childNodes blu_nodeCollectionByInsertingNode:node
                                                                                atIndex:index];
  return [BLUNode nodeWithName:self.name childNodes:childNodes value:self.value];
}

- (instancetype)nodeByInsertingChildNodes:(NSArray<BLUNode *> *)nodes
                                atIndexes:(NSIndexSet *)indexes {
  id<BLUNodeCollection> childNodes = [self.childNodes blu_nodeCollectionByInsertingNodes:nodes
                                                                               atIndexes:indexes];
  return [BLUNode nodeWithName:self.name childNodes:childNodes value:self.value];
}

- (instancetype)nodeByReplacingChildNodesAtIndexes:(NSIndexSet *)indexes
                                    withChildNodes:(NSArray<BLUNode *> *)nodes {
  id<BLUNodeCollection> childNodes = [self.childNodes
                                      blu_nodeCollectionByReplacingNodesAtIndexes:indexes
                                      withNodes:nodes];
  return [BLUNode nodeWithName:self.name childNodes:childNodes value:self.value];
}

@end

NS_ASSUME_NONNULL_END
