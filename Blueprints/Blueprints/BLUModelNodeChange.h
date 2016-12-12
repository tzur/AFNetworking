// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@class BLUNode;

/// Value class representing a single change of \c BLUNode, consisting a change in its \c value or
/// \c childNodes.
@interface BLUModelNodeChange : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Creates a new node change with the \c path of the node and the \c afterNode.
+ (instancetype)nodeChangeWithPath:(NSString *)path afterNode:(BLUNode *)afterNode;

/// Creates a new node change with the \c path of the node, \c beforeNode and \c afterNode.
+ (instancetype)nodeChangeWithPath:(NSString *)path beforeNode:(BLUNode *)beforeNode
                         afterNode:(BLUNode *)afterNode;

/// Path of the node that was changed.
@property (readonly, nonatomic) NSString *path;

/// Node before the change or \c nil if no such node is available.
@property (readonly, nonatomic, nullable) BLUNode *beforeNode;

/// Node after the change.
@property (readonly, nonatomic) BLUNode *afterNode;

@end

NS_ASSUME_NONNULL_END
