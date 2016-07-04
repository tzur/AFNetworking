// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventPredicate.h"

NS_ASSUME_NONNULL_BEGIN

/// Immutable object predicating \c id<LTContentTouchEvents> objects according to the time interval
/// between their \c timestamps, accepting an event if the interval between its \c timestamp and the
/// \c timestamp of the \c baseEvent to compare to is greater than a certain threshold.
@interface LTContentTouchEventTimeIntervalPredicate : NSObject <LTContentTouchEventPredicate>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given threshold \c interval, in seconds.
- (instancetype)initWithMinimumTimeInterval:(NSTimeInterval)interval NS_DESIGNATED_INITIALIZER;

/// Returns a predicate accepting events if the time interval between their \c timestamps is greater
/// than the given threshold \c interval, in seconds.
+ (instancetype)predicateWithMinimumTimeInterval:(NSTimeInterval)interval;

/// Time interval threshold, in seconds, for accepting events. An event is considered valid by this
/// instance if the time interval between its \c timestamp and the \c timestamp of the \c baseEvent
/// used for comparison is greater than this threshold.
@property (readonly, nonatomic) CGFloat minimumInterval;

@end

NS_ASSUME_NONNULL_END
