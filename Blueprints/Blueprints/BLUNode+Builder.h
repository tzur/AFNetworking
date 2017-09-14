// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode.h"

NS_ASSUME_NONNULL_BEGIN

@class BLUNodeBuilder;

/// Builder extensions to \c BLUNode. To build a new node or a tree, use the following syntax:
///
/// @code
/// BLUNode *node = BLUNode.builder().name(@"root").childNodes(@[
///   BLUNode.builder().name(@"firstChild").value(@5).build(),
///   BLUNode.builder().name(@"secondChild").value(@3).build(),
///   BLUNode.builder().name(@"thirdChild").build()
/// ]).build();
/// @endcode
///
/// This will create a tree that looks like this:
///
/// @code
/// /
/// |-- firstChild -> @5
/// |-- secondChild -> @3
/// |-- thirdChild -> (null)
/// @endcode
@interface BLUNode (Builder)

/// Returns a block that returns a new builder upon call.
+ (BLUNodeBuilder *(^)(void))builder;

@end

/// Utility class for easily making new \c BLUNode objects and hierarchies. One should not create
/// this class directly but call <tt>BLUNode.builder()</tt> instead.
@interface BLUNodeBuilder : NSObject

/// Sets the name of the node. This step is mandatory.
- (BLUNodeBuilder *(^)(NSString *name))name;

/// Sets the value of the node. This step is optional.
- (BLUNodeBuilder *(^)(id value))value;

/// Sets the child nodes of the node. This step is optional. Not specifying any \c childNodes will
/// build a node with an empty (but not \c nil) \c childNodes collection.
- (BLUNodeBuilder *(^)(NSArray<BLUNode *> *childNodes))childNodes;

/// Builds a node with the set parameters. If \c name has not been set, an exception will be raised.
- (BLUNode *(^)(void))build;

@end

NS_ASSUME_NONNULL_END
