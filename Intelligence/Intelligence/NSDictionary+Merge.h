// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

/// Defines merge methods and strategies for a dictionary.
@interface NSDictionary (Merge)

/// Returns an new updated dictionary after committing \c updates to the receiver. The merge is done
/// by replacing values for keys in receiver with values for the same keys from \c updates, and
/// removing keys from the receiver having an \c NSNull value in \c updates.
- (NSDictionary *)int_mergeUpdates:(NSDictionary *)updates;

@end

NS_ASSUME_NONNULL_END
