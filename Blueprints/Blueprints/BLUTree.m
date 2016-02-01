// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUTree.h"

#import <LTKit/LTRandomAccessCollection.h>

#import "BLUNode.h"
#import "BLUNode+Operations.h"
#import "NSOrderedSet+BLUNodeCollection.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BLUTree

- (instancetype)initWithRoot:(BLUNode *)root {
  if (self = [super init]) {
    _root = root;
  }
  return self;
}

+ (instancetype)treeWithRoot:(BLUNode *)root {
  return [[BLUTree alloc] initWithRoot:root];
}

- (instancetype)treeByRemovingNodeAtPath:(NSString *)path {
  NSArray<BLUNode *> * _Nullable nodes = [self nodesForPath:path];
  if (!nodes) {
    return self;
  }

  LTParameterAssert(nodes.count > 1, @"Root node cannot be removed");
  NSArray<BLUNode *> *nodesWithoutLast = [nodes subarrayWithRange:NSMakeRange(0, nodes.count - 1)];

  // Remove the node from its parent.
  BLUNode *parentNode = [nodesWithoutLast.lastObject nodeByRemovingChildNodes:@[nodes.lastObject]];

  return [self treeByUpdatingPathToRootFromNode:parentNode path:nodesWithoutLast];
}

- (instancetype)treeByAddingChildNode:(BLUNode *)node toNodeAtPath:(NSString *)path {
  NSArray<BLUNode *> * _Nullable nodes = [self nodesForPath:path];
  LTParameterAssert(nodes, @"Trying to add node %@ to a non-existing path: %@", node, path);

  // Add node to its parent.
  BLUNode *parentNode = nodes.lastObject;
  BLUNode *newParentNode = [parentNode nodeByInsertingChildNode:node
                                                        atIndex:parentNode.childNodes.count];

  return [self treeByUpdatingPathToRootFromNode:newParentNode path:nodes];
}

- (instancetype)treeByInsertingChildNode:(BLUNode *)node toNodeAtPath:(NSString *)path
                                 atIndex:(NSUInteger)index {
  NSArray<BLUNode *> * _Nullable nodes = [self nodesForPath:path];
  LTParameterAssert(nodes, @"Trying to insert node %@ to a non-existing path: %@", node, path);

  // Insert node to its parent.
  BLUNode *parentNode = nodes.lastObject;
  BLUNode *newParentNode = [parentNode nodeByInsertingChildNode:node atIndex:index];

  return [self treeByUpdatingPathToRootFromNode:newParentNode path:nodes];
}

- (instancetype)treeByReplacingNodeAtPath:(NSString *)path withNode:(BLUNode *)node {
  NSArray<BLUNode *> * _Nullable nodes = [self nodesForPath:path];
  LTParameterAssert(nodes, @"Trying to replace node %@ with a non-existing node: %@", node, path);

  // Replacing root node.
  if (nodes.count == 1) {
    return [BLUTree treeWithRoot:node];
  }

  NSArray<BLUNode *> *nodesWithoutLast = [nodes subarrayWithRange:NSMakeRange(0, nodes.count - 1)];

  // Replace node via its parent.
  BLUNode *parentNode = nodesWithoutLast.lastObject;
  NSUInteger indexToReplace = [parentNode.childNodes indexOfObject:nodes.lastObject];
  NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:indexToReplace];
  BLUNode *newParentNode = [parentNode nodeByReplacingChildNodesAtIndexes:indexes
                                                           withChildNodes:@[node]];

  return [self treeByUpdatingPathToRootFromNode:newParentNode path:nodesWithoutLast];
}

- (instancetype)treeByUpdatingPathToRootFromNode:(BLUNode *)node path:(NSArray<BLUNode *> *)path {
  // No path, node is the root.
  if (!path.count) {
    return [BLUTree treeWithRoot:node];
  }

  BLUNode *currentNode = node;

  // Update all the nodes in the path from the parent's parent to the root of the tree.
  for (NSInteger i = path.count - 2; i >= 0; --i) {
    NSUInteger indexToReplace = [path[i].childNodes indexOfObject:path[i + 1]];
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:indexToReplace];
    currentNode = [path[i] nodeByReplacingChildNodesAtIndexes:indexes
                                               withChildNodes:@[currentNode]];
  }

  return [BLUTree treeWithRoot:currentNode];
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
  [nodes addObject:self.root];

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
  [nodes addObject:self.root];

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
  [self enumerateNode:self.root withEnumerationType:enumerationType stop:&stop
       pathComponents:@[@"/"] usingBlock:block];
}

- (void)enumerateNode:(BLUNode *)node
  withEnumerationType:(BLUTreeEnumerationType)enumerationType
                 stop:(BOOL *)stop
       pathComponents:(NSArray *)pathComponents
           usingBlock:(BLUTreeEnumerationBlock)block {
  if (*stop) {
    return;
  }

  NSString *path = [NSString pathWithComponents:pathComponents];

  if (enumerationType == BLUTreeEnumerationTypePreOrder) {
    block(node, path, stop);
    if (*stop) {
      return;
    }
  }

  for (BLUNode *childNode in node.childNodes) {
    [self enumerateNode:childNode withEnumerationType:enumerationType stop:stop
         pathComponents:[pathComponents arrayByAddingObject:childNode.name] usingBlock:block];
    if (*stop) {
      return;
    }
  }

  if (enumerationType == BLUTreeEnumerationTypePostOrder) {
    block(node, path, stop);
  }
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(BLUTree *)object {
  if (self == object) {
    return YES;
  }

  if (![object isKindOfClass:BLUTree.class]) {
    return NO;
  }

  return [self.root isEqual:object.root];
}

- (NSUInteger)hash {
  return self.root.hash;
}

- (NSString *)description {
  __block NSMutableArray *nodeDescriptions = [NSMutableArray array];
  [self enumerateTreeWithEnumerationType:BLUTreeEnumerationTypePreOrder
                              usingBlock:^(BLUNode *node, NSString *path, BOOL __unused *stop) {
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

  NSString *formattedTree = [nodeDescriptions componentsJoinedByString:@"\n"];

  return [NSString stringWithFormat:@"<%@: %p,\n%@\n>", self.class, self, formattedTree];
}

@end

NS_ASSUME_NONNULL_END
