// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventStateFilter.h"

NS_ASSUME_NONNULL_BEGIN

/// Minimum distance from the initial touch event, to trigger the change to "possible" state.
extern const CGFloat kMinimumViewDistanceForPossibleState;

/// Minimum time interval from the initial touch event, to trigger the change to "possible" state.
extern const NSTimeInterval kMinimumTimeIntervalForPossibleState;

/// Minimum distance from the previous touch event.
extern const CGFloat kMinimumViewDistanceForActiveState;

/// Minimum time interval from the previous touch event.
extern const NSTimeInterval kMinimumTimeIntervalForActiveState;

/// Category adding factory methods for convenience filters of single touch event sequences,
/// balancing tolerance to small movements while still filtering most of the pinch gestures that are
/// usually used for navigation.
@interface LTContentTouchEventStateFilter (DefaultFilters)

/// Returns a convenience filter for filtering content touch events of a single content touch event
/// sequence. The filter's predicates are based only on the distance between the events'
/// \c viewLocations, hence stationary touch events are rejected as they involve no movement.
/// The thresholds used by the predicates are \c kMinimumViewDistanceForPossibleState and
/// \c kMinimumViewDistanceForActiveState respectively.
+ (instancetype)touchFilterRejectingStationaryTouches;

/// Returns a convenience filter for filtering content touch events of a single content touch event
/// sequence. The filter's predicates are based on either the events' \c viewLocations or the time
/// interval between their \c timestamps, hence stationary touch events are also accepted assuming
/// enough time has passed since the last filtered event.
/// The thresholds used by the predicates are \c kMinimumViewDistanceForPossibleState or
/// \c kMinimumTimeIntervalForPossibleState for the \c predicateForPossibleState and
/// \c kMinimumViewDistanceForActiveState or \c kMinimumTimeIntervalForActiveState for the
/// \c predicateForActiveState.
+ (instancetype)touchFilterAcceptingStationaryTouches;

@end

NS_ASSUME_NONNULL_END
