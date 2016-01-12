// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTKit/LTRandomAccessCollection.h>

NS_ASSUME_NONNULL_BEGIN

@class BLUNode;

/// Represents an immutable collection of \c BLUNode objects, which provides operations such as
/// removal, insertion, replacement and lookup by name.
///
/// @see LTRandomAccessCollection.
@protocol BLUNodeCollection <LTRandomAccessCollection>

/// Returns a new collection with the given \c nodes removed, or the same collection (although not
/// necessarily the same instance) if the nodes cannot be found in the collection.
- (instancetype)blu_nodeCollectionByRemovingNodes:(NSArray<BLUNode *> *)nodes;

/// Returns a new collection with the given \c node inserted at the given \c index. If \c index is
/// larger than the number of elements of \c childNodes, an assert will be thrown.
- (instancetype)blu_nodeCollectionByInsertingNode:(BLUNode *)node atIndex:(NSUInteger)index;

/// Returns a new collection with the objects at the given \c indexes replaced with \c nodes. The
/// \c indexes are used in the same order as the order of the given \c nodes. The \c count of
/// locations in \c indexes must be equal to the count of \c nodes.
- (instancetype)blu_nodeCollectionByReplacingNodesAtIndexes:(NSIndexSet *)indexes
                                                  withNodes:(NSArray<BLUNode *> *)nodes;

/// Returns a node with the given \c name, or \c nil if no such node is found.
- (nullable BLUNode *)blu_nodeForName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
