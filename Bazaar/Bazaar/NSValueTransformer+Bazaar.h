// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Add methods that provide \c NSValueTransformer objects that can assist with converting \c NSDate
/// to and from various representations.
@interface NSValueTransformer (Bazaar)

/// Returns a bi-directional value transformers that transforms \c NSNumber objects boxing an
/// \c NSTimeInterval that specifies a number of seconds since 1970 to a matching \c NSDate object
/// and vice versa.
+ (NSValueTransformer *)bzr_timeIntervalSince1970ValueTransformer;

@end

NS_ASSUME_NONNULL_END
