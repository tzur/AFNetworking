// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@protocol BLUNodeCollection;

/// Type of value that is held by BLUNode.
typedef id<NSCopying, NSObject> BLUNodeValue;

/// Represents a node in a tree. A node has three basic properties: \c name which identifies the
/// node, \c childNodes which is a collection of children nodes with unique names, and \c value
/// which holds the actual data of the node.
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
