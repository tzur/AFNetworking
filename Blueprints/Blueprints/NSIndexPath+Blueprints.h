// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@interface NSIndexPath (Blueprints)

/// Initializes a new \c NSIndexPath instance with the given \c indexes. If \c indexes is empty, an
/// empty \c NSIndexPath will be returned.
+ (instancetype)blu_indexPathWithIndexes:(const std::vector<NSUInteger> &)indexes;

/// Returns an empty \c NSIndexPath with a zero \c length and no indexes.
+ (instancetype)blu_empty;

/// Returns a new \c NSIndexPath by adding (appending) indexes of \c indexPath to the receiver.
- (NSIndexPath *)blu_indexPathByAddingIndexPath:(NSIndexPath *)indexPath;

/// Returns the indexes as a vector.
- (std::vector<NSUInteger>)blu_indexes;

@end

NS_ASSUME_NONNULL_END
