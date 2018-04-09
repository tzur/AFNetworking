// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTTreeNode;

/// Different orders by which tree nodes can be traversed.
typedef NS_ENUM(NSUInteger) {
  LTTreeTraversalOrderPreOrder,
  LTTreeTraversalOrderPostOrder
} LTTreeTraversalOrder;

/// Object that can be held by an \c LTTreeNode.
typedef id<NSCopying, NSObject> LTTreeNodeObject;

/// Block used for traversal of tree nodes.
typedef void (^LTTreeTraversalBlock)(LTTreeNode *node, BOOL * stop);

/// Immutable value object constituting the node of a tree. The node wraps a given
/// \c id<NSCopying, NSObject> object and maintains immutable references to its children vertices.
///
/// @important if objects of this class are abused to create a graph with cycles, any functionality
/// described by the API is undefined.
@interface LTTreeNode<ObjectType : LTTreeNodeObject> : NSObject <NSCopying, NSMutableCopying>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c object and \c children.
- (instancetype)initWithObject:(ObjectType)object
                      children:(NSArray<LTTreeNode<ObjectType> *> *)children;

/// Executes the given \c block for each node of the tree, in the given \c traversalOrder. If
/// \c stop is set to \c YES, the execution of the \c block terminates immediately.
///
/// @important the given \c stop argument is an out-only argument. It must only be modified within
/// the given \c block.
///
/// Time complexity: \c O(n), where \c is the number of vertices in this instance.
- (void)enumerateObjectsWithTraversalOrder:(LTTreeTraversalOrder)traversalOrder
                                usingBlock:(NS_NOESCAPE LTTreeTraversalBlock)block;

/// Returns \c YES if the given \c node is of class \c LTTreeNode with an equal \c object and equal
/// \c children.
///
/// Returns \n NO if \c node is \c nil.
///
/// @important calling this method might be expensive if the number of \c children is large.
///
/// Time complexity: \c O(n * m), where \c n equals the number of descendants of the receiver and
/// \c m equals the time complexity of testing equality of the \c object objects of the two involved
/// vertices.
- (BOOL)isEqual:(nullable id)node;

/// Returns a number that can be used as a table address in a hash table structure.
///
/// @important calling this method might be expensive if the number of \c children is large.
///
/// Time complexity: \c O(n * m), where \c n equals the number of descendants of the receiver and
/// \c m equals the time complexity of retrieving the hash value of the held \c object.
- (NSUInteger)hash;

/// Returns an immutable deep copy of the receiver. More explicitly, returns an
/// \c LTTreeNode<ObjectType> object which is a recursive immutable copy of the receiver.
///
/// Time complexity: \c O(n), where \c n is the number of descendants of this node.
- (LTTreeNode<ObjectType> *)deepCopy;

/// Returns a \c LTMutableTreeNode<ObjectType> object that is a copy of the receiver.
- (id)mutableCopyWithZone:(nullable NSZone *)zone;

/// Returns a mutable deep copy of the receiver. More explicitly, returns an
/// \c LTTreeNode<ObjectType> object which is a recursive mutable copy of the receiver.
///
/// Time complexity: \c O(n), where \c n is the number of descendants of this node.
- (id)mutableDeepCopy;

/// Object wrapped by this node.
@property (readonly, nonatomic) ObjectType object;

/// Ordered collection of children of this node.
@property (readonly, nonatomic) NSArray<LTTreeNode<ObjectType> *> *children;

@end

@interface LTMutableTreeNode<ObjectType : LTTreeNodeObject> : LTTreeNode

- (instancetype)init NS_UNAVAILABLE;

/// Mutable object wrapped by this node.
@property (strong, nonatomic) ObjectType object;

/// Mutable ordered collection of children of this node.
@property (readonly, nonatomic) NSMutableArray<LTTreeNode<ObjectType> *> *children;

@end

NS_ASSUME_NONNULL_END
