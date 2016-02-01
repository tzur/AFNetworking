// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@protocol BLUNodeCollection;

/// Type of value that is held by BLUNode.
typedef id<NSCopying, NSObject> BLUNodeValue;

/// Represents an immutable node of a tree. A node has three basic properties: \c name which
/// identifies the node, \c childNodes which is a collection of children nodes with unique names,
/// and \c value which holds the actual data of the node.
///
/// The node can be viewed as a root node of a tree (or a sub-tree, if this node is a child of
/// another node). For such perspective, accessing and manipulating nodes can be very useful, and is
/// provided via this class in the following forms:
///
/// Paths:
///
/// Each node in the tree can be accessed in two ways: by named path and by an index path. Named
/// paths in the tree are defined in a similar manner to a file system path: the root node is
/// accessible via the \c "/" path, and deeper nodes in the tree are accessible by appending the
/// node separator \c "/" between the node names that form the path. For example, the path
/// \c "/foo/bar" points to the node \c "bar" who's a child of the node \c "foo", who's a child of
/// the root node. Index paths in the tree are defined in a similar manner to UIKit collection or
/// table view: the root node is accessible via the empty index path, and deeper nodes in the tree
/// are accessible by appending an index that corresponds to the index of the child node of the
/// current traversed node. For example, the index path {} will point to the root node, {1} will
/// point to the second child of the root node and {1, 2} will point to the third child of the
/// second child of the root node.
///
/// One can use the subscripting operator to fetch a node at a given named path or index path, by
/// provider either an \c NSString or an \c NSIndexPath, accordingly.
///
/// Operations:
///
/// The node object is an immutable data structure which returns a new instance of the root node
/// with the requested mutation. Each mutation operation is efficient and only recreates the nodes
/// from the root to the mutated node, so for balanced trees the cost will be <tt>O(log(n))</tt>
/// where \c n is the number of nodes in the tree.
@interface BLUNode<__covariant ObjectType:BLUNodeValue> : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Creates a new node with the given \c name, collection of \c childNodes and \c value.
/// \c childNodes must not have multiple nodes with the same \c name. If the child has no nodes, an
/// empty collection should be provided. All arguments will be copied to enforce the immutability of
/// the node.
+ (instancetype)nodeWithName:(NSString *)name childNodes:(id<BLUNodeCollection>)childNodes
                       value:(ObjectType)value;

/// Name of the node.
@property (readonly, nonatomic) NSString *name;

/// Child nodes of this node.
@property (readonly, nonatomic) id<BLUNodeCollection> childNodes;

/// Value of this node.
@property (readonly, nonatomic) ObjectType value;

@end

NS_ASSUME_NONNULL_END
