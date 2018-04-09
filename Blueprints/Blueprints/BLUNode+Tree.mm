// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode+Tree.h"

#import "BLUNode+Operations.h"
#import "BLUNodeCollection.h"
#import "NSArray+BLUNodeCollection.h"
#import "NSIndexPath+Blueprints.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BLUNode (Tree)

- (instancetype)nodeByRemovingNodeAtPath:(NSString *)path {
  NSArray<BLUNode *> * _Nullable nodes = [self nodesForPath:path];
  if (!nodes) {
    return self;
  }

  LTParameterAssert(nodes.count > 1, @"Root node cannot be removed");
  NSArray<BLUNode *> *nodesWithoutLast = [nodes subarrayWithRange:NSMakeRange(0, nodes.count - 1)];

  // Remove the node from its parent.
  BLUNode *parentNode = [nodesWithoutLast.lastObject nodeByRemovingChildNodes:@[nodes.lastObject]];

  return [self nodeByUpdatingPathToRootFromNode:parentNode path:nodesWithoutLast];
}

- (instancetype)nodeByAddingChildNode:(BLUNode *)node toNodeAtPath:(NSString *)path {
  NSArray<BLUNode *> * _Nullable nodes = [self nodesForPath:path];
  LTParameterAssert(nodes, @"Trying to add node %@ to a non-existing path: %@", node, path);

  // Add node to its parent.
  BLUNode *parentNode = nodes.lastObject;
  BLUNode *newParentNode = [parentNode nodeByInsertingChildNode:node
                                                        atIndex:parentNode.childNodes.count];

  return [self nodeByUpdatingPathToRootFromNode:newParentNode path:nodes];
}

- (instancetype)nodeByInsertingChildNode:(BLUNode *)node toNodeAtPath:(NSString *)path
                                 atIndex:(NSUInteger)index {
  NSArray<BLUNode *> * _Nullable nodes = [self nodesForPath:path];
  LTParameterAssert(nodes, @"Trying to insert node %@ to a non-existing path: %@", node, path);

  // Insert node to its parent.
  BLUNode *parentNode = nodes.lastObject;
  BLUNode *newParentNode = [parentNode nodeByInsertingChildNode:node atIndex:index];

  return [self nodeByUpdatingPathToRootFromNode:newParentNode path:nodes];
}

- (instancetype)nodeByInsertingChildNodes:(NSArray<BLUNode *> *)nodes toNodeAtPath:(NSString *)path
                                atIndexes:(NSIndexSet *)indexes {
  NSArray<BLUNode *> * _Nullable nodesForPath = [self nodesForPath:path];
  LTParameterAssert(nodesForPath, @"Trying to insert nodes %@ to a non-existing path: %@", nodes,
                    path);

  // Insert nodes to their parent.
  BLUNode *parentNode = nodesForPath.lastObject;
  BLUNode *newParentNode = [parentNode nodeByInsertingChildNodes:nodes atIndexes:indexes];

  return [self nodeByUpdatingPathToRootFromNode:newParentNode path:nodesForPath];
}

- (instancetype)nodeByReplacingNodeAtPath:(NSString *)path withNode:(BLUNode *)node {
  NSArray<BLUNode *> * _Nullable nodes = [self nodesForPath:path];
  LTParameterAssert(nodes, @"Trying to replace node %@ with a non-existing node: %@", node, path);

  // Replacing root node.
  if (nodes.count == 1) {
    return node;
  }

  NSArray<BLUNode *> *nodesWithoutLast = [nodes subarrayWithRange:NSMakeRange(0, nodes.count - 1)];

  // Replace node via its parent.
  BLUNode *parentNode = nodesWithoutLast.lastObject;
  NSUInteger indexToReplace = [parentNode.childNodes indexOfObject:nodes.lastObject];
  NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:indexToReplace];
  BLUNode *newParentNode = [parentNode nodeByReplacingChildNodesAtIndexes:indexes
                                                           withChildNodes:@[node]];

  return [self nodeByUpdatingPathToRootFromNode:newParentNode path:nodesWithoutLast];
}

- (instancetype)nodeByUpdatingPathToRootFromNode:(BLUNode *)node path:(NSArray<BLUNode *> *)path {
  // No path, node is the root.
  if (!path.count) {
    return node;
  }

  BLUNode *currentNode = node;

  // Update all the nodes in the path from the parent's parent to the root of the tree.
  for (NSInteger i = (NSInteger)path.count - 2; i >= 0; --i) {
    NSUInteger indexToReplace = [path[i].childNodes indexOfObject:path[i + 1]];
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:indexToReplace];
    currentNode = [path[i] nodeByReplacingChildNodesAtIndexes:indexes
                                               withChildNodes:@[currentNode]];
  }

  return currentNode;
}

- (instancetype)nodeByRemovingAllChildNodes {
  if (!self.childNodes.count) {
    return self;
  }
  return [BLUNode nodeWithName:self.name childNodes:@[] value:self.value];
}

- (instancetype)nodeByFilteringChildNodes:(BLUNodeFilterBlock)filter atPath:(NSString *)path {
  BLUNode * _Nullable subtree = self[path];
  LTParameterAssert(subtree, @"Trying to filter child nodes of a non-existing path: %@", path);

  NSMutableArray *childNodes = [NSMutableArray array];
  for (BLUNode *childNode in subtree.childNodes) {
    if (filter(childNode)) {
      [childNodes addObject:childNode];
    }
  }

  BLUNode *newNode = [BLUNode nodeWithName:subtree.name childNodes:childNodes value:subtree.value];
  return [self nodeByReplacingNodeAtPath:path withNode:newNode];
}

- (instancetype)nodeByMappingChildNodes:(BLUNodeMapBlock)map atPath:(NSString *)path {
  BLUNode * _Nullable subtree = self[path];
  LTParameterAssert(subtree, @"Trying to map child nodes of a non-existing path: %@", path);

  NSMutableArray *childNodes = [NSMutableArray array];
  for (BLUNode *childNode in subtree.childNodes) {
    [childNodes addObject:map(childNode)];
  }

  BLUNode *newNode = [BLUNode nodeWithName:subtree.name childNodes:childNodes value:subtree.value];
  return [self nodeByReplacingNodeAtPath:path withNode:newNode];
}

- (nullable BLUNode *)objectForKeyedSubscript:(id)path {
  if ([path isKindOfClass:[NSString class]]) {
    return [self nodesForPath:path].lastObject;
  } else if ([path isKindOfClass:[NSIndexPath class]]) {
    return [self nodesForIndexPath:path].lastObject;
  } else {
    LTParameterAssert(NO, @"Path must be an NSString or NSIndexPath, got: %@", path);
  }
}

- (nullable NSArray<BLUNode *> *)nodesForPath:(NSString *)path {
  NSArray<NSString *> *pathComponents = path.pathComponents;
  if (![pathComponents.firstObject isEqualToString:@"/"]) {
    return nil;
  }

  NSMutableArray<BLUNode *> *nodes = [NSMutableArray arrayWithCapacity:pathComponents.count];
  [nodes addObject:self];

  BLUNode *currentNode = nodes.firstObject;
  for (NSUInteger i = 1; i < pathComponents.count; ++i) {
    BLUNode *node = [currentNode.childNodes blu_nodeForName:pathComponents[i]];
    if (!node) {
      return nil;
    }

    [nodes addObject:node];
    currentNode = node;
  }

  return [nodes copy];
}

- (nullable NSArray<BLUNode *> *)nodesForIndexPath:(NSIndexPath *)indexPath {
  NSMutableArray<BLUNode *> *nodes = [NSMutableArray arrayWithCapacity:indexPath.length + 1];
  [nodes addObject:self];

  BLUNode *currentNode = nodes.firstObject;
  for (NSUInteger i = 0; i < indexPath.length; ++i) {
    NSUInteger index = [indexPath indexAtPosition:i];
    if (currentNode.childNodes.count <= index) {
      return nil;
    }

    BLUNode *node = currentNode.childNodes[index];
    [nodes addObject:node];
    currentNode = node;
  }

  return [nodes copy];
}

- (void)enumerateTreeWithEnumerationType:(BLUTreeEnumerationType)enumerationType
                              usingBlock:(BLUTreeEnumerationBlock)block {
  LTParameterAssert(block);

  BOOL stop = NO;
  [self enumerateNode:self withEnumerationType:enumerationType stop:&stop
       pathComponents:@[@"/"] indexPath:[NSIndexPath blu_empty] usingBlock:block];
}

- (void)enumerateNode:(BLUNode *)node
  withEnumerationType:(BLUTreeEnumerationType)enumerationType
                 stop:(BOOL *)stop
       pathComponents:(NSArray *)pathComponents
            indexPath:(NSIndexPath *)indexPath
           usingBlock:(BLUTreeEnumerationBlock)block {
  if (*stop) {
    return;
  }

  NSString *path = [NSString pathWithComponents:pathComponents];

  if (enumerationType == BLUTreeEnumerationTypePreOrder) {
    block(node, path, indexPath, stop);
    if (*stop) {
      return;
    }
  }

  for (NSUInteger index = 0; index < node.childNodes.count; ++index) {
    BLUNode *childNode = node.childNodes[index];
    [self enumerateNode:childNode withEnumerationType:enumerationType stop:stop
         pathComponents:[pathComponents arrayByAddingObject:childNode.name]
              indexPath:[indexPath indexPathByAddingIndex:index]
             usingBlock:block];
    if (*stop) {
      return;
    }
  }

  if (enumerationType == BLUTreeEnumerationTypePostOrder) {
    block(node, path, indexPath, stop);
  }
}

- (NSString *)treeDescription {
  __block NSMutableArray *nodeDescriptions = [NSMutableArray array];
  [self enumerateTreeWithEnumerationType:BLUTreeEnumerationTypePreOrder
                              usingBlock:^(BLUNode *node, NSString *path,
                                           NSIndexPath * __unused indexPath, BOOL __unused *stop) {
    NSArray<NSString *> *components = [path pathComponents];
    NSString *nodeDescription;
    switch (components.count) {
      case 1:
        nodeDescription = @"/";
        break;
      case 2:
        nodeDescription = [NSString stringWithFormat:@"|-- %@ -> %@", node.name, node.value];
        break;
      default: {
        NSString *padding = [@"" stringByPaddingToLength:4 * components.count - 9
                                              withString:@" " startingAtIndex:0];
        nodeDescription = [NSString stringWithFormat:@"|%@`-- %@ -> %@", padding, node.name,
                           node.value];
      }
    }
    [nodeDescriptions addObject:nodeDescription];
  }];

  return [nodeDescriptions componentsJoinedByString:@"\n"];
}

@end

NS_ASSUME_NONNULL_END
