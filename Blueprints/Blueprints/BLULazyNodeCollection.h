// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNodeCollection.h"

NS_ASSUME_NONNULL_BEGIN

/// A \c BLUNodeCollection that is lifted from a \c LTRandomAccessCollection that contains \c id
/// values to \c BLUNode objects that contains these values as their values and a name that is
/// defined by a given naming block. The collection is evaluated lazily, so the new \c BLUNode items
/// are created on the fly.
@interface BLULazyNodeCollection : NSObject <BLUNodeCollection>

- (instancetype)init NS_UNAVAILABLE;

/// Block for returning a name of a node given its value. This will be used for lifting values in
/// collections to their container node.
typedef NSString * _Nonnull(^BLUNodeNamingBlock)(id value);

/// Initializes a new node collection with the given underlying \c collection, which serves as the
/// values of the nodes in the returned collection. The name of each node will be determined by the
/// given \c namingBlock, which should only depend on the value of the node or fixed values, and
/// should provide unique name for each item in the underlying collection, to preserve
/// \c BLUNodeCollection invariant. The returned nodes will have no \c childNodes.
- (instancetype)initWithCollection:(id<LTRandomAccessCollection>)collection
                       namingBlock:(BLUNodeNamingBlock)namingBlock NS_DESIGNATED_INITIALIZER;

/// Underlying collection held by this node collection.
@property (readonly, nonatomic) id<LTRandomAccessCollection> collection;

@end

NS_ASSUME_NONNULL_END
