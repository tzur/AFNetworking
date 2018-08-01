// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

NS_ASSUME_NONNULL_BEGIN

/// Allows to convert \c NSArray to \c NSSet in a functional manner.
@interface NSArray<ObjectType> (NSSet)

/// Returns a new \c NSSet from the array. When the array is not \c nil, this is identical to
/// calling:
//
/// @code
/// [NSSet setWithArray:self];
/// @endcode
- (NSSet<ObjectType> *)lt_set;

/// Returns a new \c NSOrderedSet from the array. When the array is not \c nil, this is identical to
/// calling:
//
/// @code
/// [NSOrderedSet orderedSetWithArray:self];
/// @endcode
- (NSOrderedSet<ObjectType> *)lt_orderedSet;

@end

NS_ASSUME_NONNULL_END
