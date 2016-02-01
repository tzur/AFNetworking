// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@interface NSIndexPath (Blueprints)

/// Initializes a new \c NSIndexPath instance with the given \c indexes. If \c indexes is empty, an
/// empty \c NSIndexPath will be returned.
+ (instancetype)blu_indexPathWithIndexes:(const std::vector<NSUInteger> &)indexes;

/// Returns an empty \c NSIndexPath with a zero \c length and no indexes.
+ (instancetype)blu_empty;

@end

NS_ASSUME_NONNULL_END
