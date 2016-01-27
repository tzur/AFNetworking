// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BLUNodeCollection;

/// Value class that holds the data part of the node, namely its value and child nodes.
@interface BLUNodeData<__covariant ObjectType:BLUNodeValue> : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes a new node data with its value and child nodes.
+ (instancetype)nodeDataWithValue:(ObjectType)value childNodes:(id<BLUNodeCollection>)childNodes;

/// Value of this node.
@property (readonly, nonatomic) ObjectType value;

/// Child nodes of the node.
@property (readonly, nonatomic) id<BLUNodeCollection> childNodes;

@end

NS_ASSUME_NONNULL_END
