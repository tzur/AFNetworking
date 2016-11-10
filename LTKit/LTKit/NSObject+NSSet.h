// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting \c NSObject with a convenience method for functionally creating an \c NSSet
/// containing the receiver, or its contents in case of an array.
@interface NSObject (NSSet)

/// Returns a new \c NSSet containing the receiver. If the receiver is not \c nil and not an
/// \c NSArray, this is identical to calling:
//
/// @code
/// [NSSet setWithObject:self];
/// @endcode
///
/// If the receiver is an \c NSArray, the more specific \c lt_set method defined by the
/// \c NSArray+NSSet category is used.
- (NSSet *)lt_set;

@end

NS_ASSUME_NONNULL_END
