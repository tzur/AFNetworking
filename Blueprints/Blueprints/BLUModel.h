// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BLUNodeCollection;

@class BLUTree, RACSignal;

/// Represents a model that is backed by \c BLUTree. In contrast to \c BLUTree, the model is a
/// stateful object that holds the latest tree that was produced from the series of transformations
/// on the model.
///
/// The model allows to mutate itself by replacing a value of a node or its child nodes (but not
/// renaming its path or deleting existing nodes). The mutations can be observed by observing a
/// specific node for changes or by observing the entire backing tree and retriving the new tree
/// once the mutation is complete.
///
/// @important This class is thread safe, so multiple mutations on the model can be performed from
/// multiple threads while keeping the model consistent. However, it is not reentrant safe when
/// reentering from multiple threads. Such operation may yield a deadlock.
@interface BLUModel : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the initial tree this model is composed of.
- (instancetype)initWithTree:(BLUTree *)tree NS_DESIGNATED_INITIALIZER;

/// Replaces the value of a node at the given \c path with the given \c value.
- (void)replaceValueOfNodeAtPath:(NSString *)path withValue:(BLUNodeValue)value;

/// Replaces the child nodes of the node at the given \c path with the given \c childNodes.
- (void)replaceChildNodesOfNodeAtPath:(NSString *)path
                       withChildNodes:(id<BLUNodeCollection>)childNodes;

/// Listens to changes to the \c value or \c childNodes of the node at the given \c path. If \c path
/// doesn't exist, the signal will err. If the node is removed while it is being observed, the
/// signal will complete. Values will be sent on an arbitrary scheduler.
- (RACSignal *)changesForNodeAtPath:(NSString *)path;

/// Returns a signal of \c BLUTree objects that sends the initial tree and a new tree each time it
/// is changed. Values will be sent on an arbitrary scheduler.
- (RACSignal *)treeModel;

@end

NS_ASSUME_NONNULL_END
