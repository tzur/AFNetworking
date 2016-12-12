// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@interface NSIndexSet (Blueprints)

/// Creates a new \c NSIndexSet with the given \c indexes.
+ (instancetype)blu_indexSetWithIndexes:(const std::set<NSUInteger> &)indexes;

@end

NS_ASSUME_NONNULL_END
