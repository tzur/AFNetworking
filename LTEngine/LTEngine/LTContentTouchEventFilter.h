// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEvent.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTContentTouchEventPredicate;

/// Stateful object filtering incoming \c id<LTContentTouchEvent> objects with an
/// \c id<LTContentTouchEventPredicate> object, such that each incoming event is tested against the
/// last valid event prior to it.
@interface LTContentTouchEventFilter : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c predicate.
- (instancetype)initWithPredicate:(id<LTContentTouchEventPredicate>)predicate
    NS_DESIGNATED_INITIALIZER;

/// Returns a collection of filtered events, such that \c predicate accepts the first event compared
/// to \c lastValidEvent, and then for every pair of successive events. In case \c lastValidEvent is
/// \c nil, the first event in the collection will be accepted.
- (LTContentTouchEvents *)pushEventsAndFilter:(LTContentTouchEvents *)events;

/// Predicate used for filtering ordered collections of \c id<LTContentTouchEvent> objects.
@property (readonly, nonatomic) id<LTContentTouchEventPredicate> predicate;

/// The last event that was pushed into the filter and accepted by \c predicate, or \c nil if no
/// event has been accepted yet.
@property (readonly, nonatomic, nullable) id<LTContentTouchEvent> lastValidEvent;

@end

NS_ASSUME_NONNULL_END
