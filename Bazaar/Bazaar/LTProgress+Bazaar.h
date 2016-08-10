// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import <LTKit/LTProgress.h>

NS_ASSUME_NONNULL_BEGIN

/// Adds convenience methods for working with \c LTProgress in Bazaar.
@interface LTProgress (Bazaar)

/// Creates and returns a new instance of \c LTProgress initialized with \c progress value set to
/// <tt>completedUnitCount / totalUnitCount</tt>. Both \c totalUnitCount and \c completedUnitCount
/// must not be negative.
///
/// @note If \c totalUnits is \c 0 the \c progress property of the returned \c LTProgress will be
/// \c 0.
+ (instancetype)progressWithTotalUnitCount:(NSNumber *)totalUnitCount
                        completedUnitCount:(NSNumber *)completedUnitCount;

@end

NS_ASSUME_NONNULL_END
