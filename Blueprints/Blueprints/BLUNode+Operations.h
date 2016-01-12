// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode.h"

NS_ASSUME_NONNULL_BEGIN

/// Operations that can be performed on \c BLUNode.
@interface BLUNode (Operations)

/// Returns a new node with the same \c name and \c value, but with \c childNodes that do not
/// contain the given \c nodes, or returns an unmodified node (either \c self or a copy) if \c nodes
/// cannot be found.
- (instancetype)nodeByRemovingChildNodes:(NSArray<BLUNode *> *)nodes;

/// Returns a new node with the same \c name and \c value, but with \c childNodes that contain
/// \c node at the given \c index. If \c index is larger than the number of elements of
/// \c childNodes, an assert will be thrown.
- (instancetype)nodeByInsertingChildNode:(BLUNode *)node atIndex:(NSUInteger)index;

/// Returns a new node with the same \c name and \c value, but with \c childNodes at the given
/// \c indexes replaced with \c nodes. The \c indexes are used in the same order as the order of the
/// given \c nodes. The \c count of locations in \c indexes must be equal to the count of \c nodes.
- (instancetype)nodeByReplacingChildNodesAtIndexes:(NSIndexSet *)indexes
                                    withChildNodes:(NSArray<BLUNode *> *)nodes;

@end

NS_ASSUME_NONNULL_END
