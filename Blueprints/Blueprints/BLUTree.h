// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@class BLUNode;

/// Represents an immutable tree that holds \c BLUNode objects as its nodes.
///
/// Paths:
///
/// Paths in the tree are defined in a similar manner to a file system path: the root node is
/// accessible via the \c "/" path, and deeper nodes in the tree are accessible by appending the
/// node separator \c "/" between the node names that form the path. For example, the path
/// \c "/foo/bar" points to the node \c "bar" who's a child of the node \c "foo", who's a child of
/// the root node. One can use the subscripting operator to fetch a node at a given path.
///
/// Operations:
///
/// The tree object is an immutable data structure which returns a new instance of a tree with the
/// requested mutation. The copy operation of the tree is efficient and only recreates the nodes
/// from the root to the mutated node.
@interface BLUTree : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a tree with the given \c root node.
+ (instancetype)treeWithRoot:(BLUNode *)root;

/// Returns a new tree that is formed by removing the node from the receiver at the given \c path.
/// If the given \c path does not point to any node, the returned tree will be equal to the
/// receiver. If \c path points to the root node, an assert will be raised.
- (instancetype)treeByRemovingNodeAtPath:(NSString *)path;

/// Returns a new tree that is formed by adding the given \c node as a child to the node at the
/// given \c path. If \c path does not point to any node, an assert will be raised.
- (instancetype)treeByAddingChildNode:(BLUNode *)node toNodeAtPath:(NSString *)path;

/// Returns a new tree that is formed by inserting the given \c node as a child to the node at the
/// given \c path at the given \c index. If \c index is already occupied, the objects at \c index
/// and beyond are shifted by adding \c 1 to their indexes to make room. The valid value range of
/// \c index is <tt>[0..childNodes.count]</tt>. If an invalid index is given, an assert will be
/// raised. If \c path does not point to any node, an assert will be raised.
- (instancetype)treeByInsertingChildNode:(BLUNode *)node toNodeAtPath:(NSString *)path
                                 atIndex:(NSUInteger)index;

/// Returns a new tree that is formed by replacing the node at the given \c path with the given
/// \c node. If \c path does not point to any node, an assert will be raised.
- (instancetype)treeByReplacingNodeAtPath:(NSString *)path withNode:(BLUNode *)node;

/// Returns the node at the given \c path or \c nil if no such node is found.
- (nullable BLUNode *)objectForKeyedSubscript:(NSString *)path;

/// Root node of the tree.
@property (readonly, nonatomic) BLUNode *root;

@end

NS_ASSUME_NONNULL_END
