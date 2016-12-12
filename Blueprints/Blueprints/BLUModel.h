// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "BLUNode.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BLUNodeCollection;

@class BLUNode, RACSignal;

/// Represents a model that is backed by \c BLUNode that represents a root node of a tree. In
/// contrast to \c BLUNode, the model is a stateful object that holds the latest tree that was
/// produced from the series of transformations on the model.
///
/// The model allows to mutate itself by replacing a value of a node or its child nodes (but not
/// renaming its path or deleting existing nodes). The mutations can be observed by observing a
/// specific node for changes or by observing the entire backing tree and retriving the new tree
/// once the mutation is complete.
///
/// The model itself cannot be modified by an external client. To modify the model, one need to
/// create a node in the initial given \c tree that holds a value that implements the
/// \c BLUProviderDescriptor protocol. This descriptor describes how to create a provider that will
/// be attached to the model and mutate it when data is added, changed or removed.
///
/// @important This class is thread safe, so multiple mutations on the model can be performed from
/// multiple threads while keeping the model consistent. However, it is not reentrant safe when
/// reentering from multiple threads. Such operation may yield a deadlock.
@interface BLUModel : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the initial root node of a tree this model is composed of. The initial tree
/// will be iterated, and every node that holds a value that conforms to \c BLUProviderDescriptor
/// will be replaced with a node of an initial value of <tt>[NSNull null]</tt> and an empty array as
/// child nodes, and will be attached to a provider created using the descriptor. Upon any update of
/// value or child nodes from the provider, the model will be changed and changes will be sent to
/// listeners.
- (instancetype)initWithRootNode:(BLUNode *)rootNode NS_DESIGNATED_INITIALIZER;

/// Listens to changes to the \c value or \c childNodes of the node at the given \c path. If \c path
/// doesn't exist, the signal will err. If the node is removed while it is being observed, the
/// signal will complete. Values will be sent on an arbitrary scheduler.
///
/// @see BLUNode+Tree for more information about how to format \c path.
- (RACSignal *)changesForNodeAtPath:(NSString *)path;

/// Returns a signal of \c BLUNode objects that sends the current root node of the tree and a new
/// tree each time it is changed. Values will be sent on an arbitrary scheduler.
- (RACSignal *)currentRootNode;

@end

NS_ASSUME_NONNULL_END
