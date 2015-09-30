// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

/// Implementation of a container of a single object that is held weakly by the container.
@interface LTWeakContainer<ObjectType> : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the container with the given \c object.
- (instancetype)initWithObject:(nullable ObjectType)object NS_DESIGNATED_INITIALIZER;

/// Object that is weakly held by the container. Will be automatically set to \c nil when it is
/// deallocated.
@property (readonly, weak, nonatomic, nullable) ObjectType object;

@end

NS_ASSUME_NONNULL_END
