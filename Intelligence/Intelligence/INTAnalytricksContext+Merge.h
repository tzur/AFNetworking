// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAnalytricksContext.h"

NS_ASSUME_NONNULL_BEGIN

/// Category for copying an \c INTAnalytricksContext.
@interface INTAnalytricksContext (Merge)

/// Returns an new \c INTAnalytricksContext instance initialized with a dictionary that is a merge
/// of \c updates and the receivers properties. The merge is done by replacing values for keys in
/// receivers' properties with values for the same keys from \c updates, and setting keys having an
/// \c NSNull value from the resulting object.
///
/// @attention only valid keys for properties - invalid ones are discarded. Values are not checked
/// for type safety.
- (instancetype)merge:(NSDictionary<NSString *, id> *)dictionary;

@end

NS_ASSUME_NONNULL_END
