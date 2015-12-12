// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTInterval.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol which should be implemented by immutable value classes representing a discrete set,
/// \c S, of \c CGFloat values. Upon queries with an \c lt::Interval, the implementing objects
/// return an ordered collection of \c CGFloats constituting the subset of \c S contained by the
/// given interval.
///
/// Example 1: An object conforming to this protocol may represent a discrete set of equidistant
/// \c CGFloat values.
///
/// Example 2: An object conforming to this protocol may represent a discrete set of \c CGFloat
/// values with increasing distance.
@protocol LTFloatSet <NSObject>

/// Returns an ordered collection of \c CGFloats belonging to the set represented by this object and
/// contained by the given \c interval.
- (CGFloats)discreteValuesInInterval:(const lt::Interval<CGFloat> &)interval;

@end

NS_ASSUME_NONNULL_END
