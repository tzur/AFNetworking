// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventStateFilter.h"

#import "LTContentTouchEventFilter.h"
#import "LTContentTouchEventPredicate.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTContentTouchEventStateFilter ()

/// First touch event of the currently active touch sequence.
@property (strong, nonatomic, nullable) id<LTContentTouchEvent> sequenceInitialTouchEvent;

/// Object used to filter touch events when in the active state.
@property (strong, nonatomic, nullable) LTContentTouchEventFilter *eventsFilter;

/// Current state of this instance.
@property (readwrite, nonatomic) LTContentTouchEventStateFilterState filterState;

@end

@implementation LTContentTouchEventStateFilter

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)
    initWithPredicateForPossibleState:(id<LTContentTouchEventPredicate>)predicateForPossibleState
              predicateForActiveState:(id<LTContentTouchEventPredicate>)predicateForActiveState {
  if (self = [super init]) {
    _predicateForPossibleState = predicateForPossibleState;
    _predicateForActiveState = predicateForActiveState;
    self.filterState = LTContentTouchEventStateFilterStateIdle;
  }
  return self;
}

#pragma mark -
#pragma mark Filtering
#pragma mark -

- (LTContentTouchEvents *)filterContentTouchEvents:(LTContentTouchEvents *)contentTouchEvents
                            withTouchSequenceState:(LTTouchEventSequenceState)state {
  [self validateIncomingSequenceState:state];

  switch (state) {
    case LTTouchEventSequenceStateStart:
      [self startTouchSequenceWithContentTouchEvents:contentTouchEvents];
      return contentTouchEvents;
    case LTTouchEventSequenceStateContinuation:
    case LTTouchEventSequenceStateContinuationStationary:
      return [self filterContentTouchEvents:contentTouchEvents];
    case LTTouchEventSequenceStateEnd:
    case LTTouchEventSequenceStateCancellation:
      [self endTouchSequenceWithContentTouchEvents:contentTouchEvents];
      return contentTouchEvents;
  }
}

- (void)validateIncomingSequenceState:(LTTouchEventSequenceState)state {
  switch (self.filterState) {
    case LTContentTouchEventStateFilterStateIdle:
      LTParameterAssert(state == LTTouchEventSequenceStateStart,
                        @"Invalid sequence state (%lu) provided for filter state (%lu)",
                        (unsigned long)state, (unsigned long)self.filterState);
      break;
    case LTContentTouchEventStateFilterStatePossible:
    case LTContentTouchEventStateFilterStateActive:
      LTParameterAssert(state == LTTouchEventSequenceStateContinuation ||
                        state == LTTouchEventSequenceStateContinuationStationary ||
                        state == LTTouchEventSequenceStateEnd ||
                        state == LTTouchEventSequenceStateCancellation,
                        @"Invalid sequence state (%lu) provided for filter state (%lu)",
                        (unsigned long)state, (unsigned long)self.filterState);
      break;
  }
}

- (void)startTouchSequenceWithContentTouchEvents:(LTContentTouchEvents *)events {
  LTParameterAssert(events.count == 1, @"Expected a single event for sequence start, got %lu",
                    (unsigned long)events.count);

  self.filterState = LTContentTouchEventStateFilterStatePossible;
  self.sequenceInitialTouchEvent = events.firstObject;
  self.eventsFilter = [[LTContentTouchEventFilter alloc]
                       initWithPredicate:self.predicateForActiveState];
  [self.eventsFilter pushEventsAndFilter:events];
}

- (LTContentTouchEvents *)filterContentTouchEvents:(LTContentTouchEvents *)events {
  if (self.filterState == LTContentTouchEventStateFilterStatePossible) {
    events = [self filteredEventsByTrimmingInitialMovement:events];
    if (events.count) {
      self.filterState = LTContentTouchEventStateFilterStateActive;
    }
  }

  return [self.eventsFilter pushEventsAndFilter:events];
}

- (LTContentTouchEvents *)filteredEventsByTrimmingInitialMovement:(LTContentTouchEvents *)events {
  LTAssert(self.sequenceInitialTouchEvent, @"sequenceInitialTouchEvent must be set while in "
           "state %lu", (unsigned long)self.filterState);

  NSUInteger firstValidEvent =
      [events indexOfObjectPassingTest:^BOOL(id<LTContentTouchEvent> event, NSUInteger, BOOL *) {
    return [self.predicateForPossibleState isValidEvent:event
                                             givenEvent:self.sequenceInitialTouchEvent];
  }];

  return firstValidEvent != NSNotFound ?
      [events subarrayWithRange:NSMakeRange(firstValidEvent, events.count - firstValidEvent)] : @[];
}

- (void)endTouchSequenceWithContentTouchEvents:(LTContentTouchEvents *)events {
  LTParameterAssert(events.count == 1, @"Expected a single event for sequence end/cancel, got %lu",
                    (unsigned long)events.count);
  [self resetToIdleState];
}

- (void)cancelActiveSequence {
  [self resetToIdleState];
}

- (void)resetToIdleState {
  self.filterState = LTContentTouchEventStateFilterStateIdle;
  self.eventsFilter = nil;
  self.sequenceInitialTouchEvent = nil;
}

@end

NS_ASSUME_NONNULL_END
