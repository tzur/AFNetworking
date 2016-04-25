// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode.h"

NS_ASSUME_NONNULL_BEGIN

/// Types for enumerating the tree.
typedef NS_ENUM(NSUInteger, BLUTreeEnumerationType) {
  BLUTreeEnumerationTypePreOrder,
  BLUTreeEnumerationTypePostOrder
};

/// Adds tree-perspective operations to \c BLUNode.
@interface BLUNode (Tree)

/// Returns a new node that is formed by removing the node from the receiver at the given \c path.
/// If the given \c path does not point to any node, the returned node will be equal to the
/// receiver. If \c path points to the receiver, an exception will be raised.
- (instancetype)nodeByRemovingNodeAtPath:(NSString *)path;

/// Returns a new node that is formed by adding the given \c node as a child to the node at the
/// given \c path. If \c path does not point to any node, an exception will be raised.
- (instancetype)nodeByAddingChildNode:(BLUNode *)node toNodeAtPath:(NSString *)path;

/// Returns a new node that is formed by inserting the given \c node as a child to the node at the
/// given \c path at the given \c index. If \c index is already occupied, the objects at \c index
/// and beyond are shifted by adding \c 1 to their indexes to make room. The valid value range of
/// \c index is <tt>[0..childNodes.count]</tt>. If an invalid index is given, an exception will be
/// raised. If \c path does not point to any node, an exception will be raised.
- (instancetype)nodeByInsertingChildNode:(BLUNode *)node toNodeAtPath:(NSString *)path
                                 atIndex:(NSUInteger)index;

/// Returns a new node that is formed by inserting the given \c nodes as childs to the node at the
/// given \c path at the given \c indexes. Each node in \c nodes is inserted in turn at the
/// corresponding location specified in \c indexes after earlier insertions have been made. If one
/// of the indexes, at the time of the insert, exceeds <tt>[0..childNodes.count]</tt>, an exception
/// will be raised. If \c path does not point to any node, an exception will be raised.
///
/// @important \c indexes is a sorted collection, thus creating a non-sorted \c NSIndexSet and
/// passing it to this method will produce unexpected results.
- (instancetype)nodeByInsertingChildNodes:(NSArray<BLUNode *> *)nodes toNodeAtPath:(NSString *)path
                                atIndexes:(NSIndexSet *)indexes;

/// Returns a new node that is formed by replacing the node at the given \c path with the given
/// \c node. If \c path does not point to any node, an exception will be raised.
- (instancetype)nodeByReplacingNodeAtPath:(NSString *)path withNode:(BLUNode *)node;

/// Returns the node at the given \c path or \c nil if no such node is found. \c path can be either
/// an \c NSString or an \c NSIndexPath. If \c path is an \c NSString, the returned node will be
/// resolved by traversing the names of the node, starting from the receiver. If \c path is
/// \c NSIndexPath, the returned node will be resolved by traversing the indexes of the child nodes,
/// starting from the receiver. An empty index path refers to the receiver.
- (nullable BLUNode *)objectForKeyedSubscript:(id)path;

/// Enumeration block that provides the next \c node at the given \c path in the tree and an
/// out-only argument \c stop used to stop the enumeration by setting it to \c YES, if needed.
typedef void (^BLUTreeEnumerationBlock)(BLUNode *node, NSString *path, BOOL *stop);

/// Enumerates the tree with the given \c enumerationType, by calling \c block with the next node.
/// If \c stop is set to \c YES, the enumeration will be stopped.
- (void)enumerateTreeWithEnumerationType:(BLUTreeEnumerationType)enumerationType
                              usingBlock:(BLUTreeEnumerationBlock)block;

/// Returns a complete description of the tree as seen by a pre-ordered enumerator, in the following
/// format:
///
/// @code
/// /
/// |-- node1 -> value1
/// |-- node2 -> value2
/// |   `-- childNode1 -> value3
/// |       `-- grandChild1 -> value4
/// |   `-- childNode2 -> value5
/// ...
/// @endcode
///
/// Generating the description requires iteration on the entire tree, and may be a heavy operation
/// if the tree contains many nodes.
- (NSString *)treeDescription;

@end

NS_ASSUME_NONNULL_END
