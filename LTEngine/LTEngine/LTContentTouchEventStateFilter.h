// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTContentTouchEventPredicate;

/// Possible states for the \c LTContentTouchEventStateFilter.
typedef NS_ENUM(NSUInteger, LTContentTouchEventStateFilterState) {
  /// State of the filter while waiting for an \c LTTouchEventSequenceStateStart event.
  LTContentTouchEventStateFilterStateIdle,
  /// State of the filter after an \c LTTouchEventSequenceStateStart event and before a triggering
  /// event has occured since the initial event.
  LTContentTouchEventStateFilterStatePossible,
  /// State of the filter after the triggering event has occured, and until either
  /// \c LTTouchEventSequenceStateEnd or \c LTTouchEventSequenceStateCancellation events are
  /// processed, or \c cancelActiveSequence is called.
  LTContentTouchEventStateFilterStateActive
};

/// Stateful object filtering incoming \c id<LTContentTouchEvent> objects based on their
/// \c LTTouchEventSequenceState and predicates chosen according to one of three states: "idle",
/// "possible" and "active".
/// - "Idle" state (default): For incoming content touch events with sequence state other than
///   \c LTTouchEventSequenceStateStart the instance ignores the events and remains in the idle
///   state. Upon receiving a content touch event with sequence state
///   \c LTTouchEventSequenceStateStart, the instance transitions into the "possible" state
///
/// - In "possible" state, each incoming \c LTTouchEventSequenceStateContinuation or
///   \c LTTouchEventStateContinuationStationary event is tested against the first event of the
///   sequence using the \c predicateForPossibleState. When an event passes the test the filter
///   moves to "active" state. In case an \c LTTouchEventSequenceStateEnd or
///   \c LTTouchEventSequenceStateCancellation is received, the filter returns to "idle state".
///
/// - In "active" state, each incoming \c LTTouchEventSequenceStateContinuation or
///   \c LTTouchEventStateContinuationStationary event is tested using \c predicateForActiveState
///   against the last event that passed that predicate. The filter remains in this state until an
///   \c LTTouchEventSequenceStateEnd or \c LTTouchEventSequenceStateCancellation event is received,
///   returning it to "idle" state.
@interface LTContentTouchEventStateFilter : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given predicates to use in the different filter states.
- (instancetype)
    initWithPredicateForPossibleState:(id<LTContentTouchEventPredicate>)predicateForPossibleState
              predicateForActiveState:(id<LTContentTouchEventPredicate>)predicateForActiveState
    NS_DESIGNATED_INITIALIZER;

/// Filters the given \c contentTouchEvents according to their sequence \c state and current filter
/// state. Returns the filtered array which might be empty in case \c state is either
/// \c LTTouchEventSequenceStateContinuation or \c LTTouchEventSequenceStateContinuationStationary.
/// Raises \c NSInvalidArgumentException in case the given \c state is invalid for the current
/// filter state.
- (LTContentTouchEvents *)filterContentTouchEvents:(LTContentTouchEvents *)contentTouchEvents
                            withTouchSequenceState:(LTTouchEventSequenceState)state;

/// Cancels any currently active sequence and returns to "idle" state. This method can be called in
/// any of the filter states.
- (void)cancelActiveSequence;

/// Current state of the filter.
@property (readonly, nonatomic) LTContentTouchEventStateFilterState filterState;

/// Predicate used for testing incoming events during "possible" state.
@property (readonly, nonatomic) id<LTContentTouchEventPredicate> predicateForPossibleState;

/// Predicate used for testing incoming events during "active" state.
@property (readonly, nonatomic) id<LTContentTouchEventPredicate> predicateForActiveState;

@end

NS_ASSUME_NONNULL_END
