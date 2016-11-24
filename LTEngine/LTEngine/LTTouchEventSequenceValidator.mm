// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventSequenceValidator.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTTouchEventSequenceValidator ()

/// Strongly held delegate. Is \c nil if \c weaklyHeldDelegate is not \c nil or no delegate has been
/// provided upon initialization.
@property (readonly, nonatomic, nullable ) id<LTTouchEventDelegate> stronglyHeldDelegate;

/// Weakly held delegate. Is \c nil if \c stronglyHeldDelegate is not \c nil or no delegate has been
/// provided upon initialization.
@property (weak, readonly, nonatomic, nullable) id<LTTouchEventDelegate> weaklyHeldDelegate;

/// Mapping of IDs of incoming touch event sequences to their current state.
@property (readonly, nonatomic) NSMutableDictionary<NSNumber *, NSNumber *> *sequenceIDToState;

@end

@implementation LTTouchEventSequenceValidator

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return [self initWithDelegate:nil heldStrongly:YES];
}

- (instancetype)initWithDelegate:(nullable id<LTTouchEventDelegate>)delegate
                    heldStrongly:(BOOL)heldStrongly {
  if (self = [super init]) {
    _stronglyHeldDelegate = heldStrongly ? delegate : nil;
    _weaklyHeldDelegate = !heldStrongly ? delegate : nil;
    _sequenceIDToState = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark -
#pragma mark LTTouchEventDelegate
#pragma mark -

- (void)receivedTouchEvents:(LTTouchEvents *)touchEvents
            predictedEvents:(LTTouchEvents *)predictedTouchEvents
    touchEventSequenceState:(LTTouchEventSequenceState)state {
  LTParameterAssert(touchEvents.count);

  NSUInteger sequenceID = touchEvents.firstObject.sequenceID;
  NSTimeInterval timestamp = touchEvents.firstObject.timestamp;

  for (id<LTTouchEvent> touchEvent in touchEvents) {
    LTParameterAssert(touchEvent.sequenceID == sequenceID,
                      @"Touch event %@ does not have expected sequence ID %lu", touchEvent,
                      (unsigned long)sequenceID);
    LTParameterAssert(touchEvent.timestamp >= timestamp,
                      @"Timestamp (%g) of touch event %@ is smaller than timestamp (%g) of "
                      "previous touch event", touchEvent.timestamp, touchEvent, timestamp);
    timestamp = touchEvent.timestamp;
  }

  timestamp = predictedTouchEvents.firstObject.timestamp;

  for (id<LTTouchEvent> predictedTouchEvent in predictedTouchEvents) {
    LTParameterAssert(predictedTouchEvent.timestamp >= timestamp,
                      @"Timestamp (%g) of predicted touch event %@ is smaller than timestamp (%g) "
                      "of previous touch event", predictedTouchEvent.timestamp, predictedTouchEvent,
                      timestamp);
    timestamp = predictedTouchEvent.timestamp;
  }

  NSNumber *boxedSequenceID = @(sequenceID);

  if (state == LTTouchEventSequenceStateStart) {
    LTParameterAssert(touchEvents.count == 1, @"Expected sequence with single touch event, "
                      "received sequence with %lu touch events",
                      (unsigned long)touchEvents.count);
    LTParameterAssert(!self.sequenceIDToState[boxedSequenceID], @"Sequence ID (%lu) already added",
                      (unsigned long)sequenceID);
  } else {
    [self validateStateOfExistingSequenceWithID:boxedSequenceID andState:state];
  }

  if (state == LTTouchEventSequenceStateEnd || state == LTTouchEventSequenceStateCancellation) {
    [self.sequenceIDToState removeObjectForKey:boxedSequenceID];
  } else {
    self.sequenceIDToState[boxedSequenceID] = @(state);
  }

  [self.delegate receivedTouchEvents:touchEvents predictedEvents:predictedTouchEvents
             touchEventSequenceState:state];
}

- (void)validateStateOfExistingSequenceWithID:(NSNumber *)sequenceID
                                     andState:(LTTouchEventSequenceState)state {
  LTParameterAssert(self.sequenceIDToState[sequenceID],
                    @"Sequence ID (%lu) not added yet",
                    (unsigned long)sequenceID.unsignedIntegerValue);

  LTTouchEventSequenceState previousState =
      (LTTouchEventSequenceState)self.sequenceIDToState[sequenceID].unsignedIntegerValue;

  switch (previousState) {
    case LTTouchEventSequenceStateStart:
    case LTTouchEventSequenceStateContinuation:
    case LTTouchEventSequenceStateContinuationStationary:
      LTParameterAssert(state == LTTouchEventSequenceStateContinuation ||
                        state == LTTouchEventSequenceStateContinuationStationary ||
                        state == LTTouchEventSequenceStateEnd ||
                        state == LTTouchEventSequenceStateCancellation,
                        @"Invalid state (%lu) for previous state (%lu)", (unsigned long)state,
                        (unsigned long)previousState);
      break;
    case LTTouchEventSequenceStateEnd:
      LTParameterAssert(NO, @"Additional method call for ended sequence with ID %lu",
                        (unsigned long)sequenceID.unsignedIntegerValue);
      break;
    case LTTouchEventSequenceStateCancellation:
      LTParameterAssert(NO, @"Additional method call for cancelled sequence with ID %lu",
                        (unsigned long)sequenceID.unsignedIntegerValue);
      break;
  }
}

- (void)receivedUpdatesOfTouchEvents:(LTTouchEvents *)touchEvents {
  LTParameterAssert(touchEvents.count);

  NSTimeInterval timestamp = touchEvents.firstObject.timestamp;

  for (id<LTTouchEvent> touchEvent in touchEvents) {
    LTParameterAssert(self.sequenceIDToState[@(touchEvent.sequenceID)],
                      @"Received update of touch event %@ belonging to sequence (ID: %lu) that "
                      "does not exist", touchEvent, (unsigned long)touchEvent.sequenceID);
    LTParameterAssert(touchEvent.timestamp >= timestamp,
                      @"Timestamp (%g) of received touch event %@ is smaller than timestamp (%g) "
                      "of previous touch event", touchEvent.timestamp, touchEvent, timestamp);
    timestamp = touchEvent.timestamp;
  }

  [self.delegate receivedUpdatesOfTouchEvents:touchEvents];
}

- (void)touchEventSequencesWithIDs:(NSSet<NSNumber *> *)sequenceIDs
               terminatedWithState:(LTTouchEventSequenceState)state {
  LTParameterAssert(sequenceIDs.count);

  for (NSNumber *sequenceID in sequenceIDs) {
    LTParameterAssert(self.sequenceIDToState[sequenceID], @"Received ID (%lu) of sequence that "
                      "does not exist", (unsigned long)sequenceID.unsignedIntegerValue);
    [self.sequenceIDToState removeObjectForKey:sequenceID];
  }

  LTParameterAssert(state == LTTouchEventSequenceStateEnd ||
                    state == LTTouchEventSequenceStateCancellation, @"Invalid state: %lu",
                    (unsigned long)state);

  [self.delegate touchEventSequencesWithIDs:sequenceIDs terminatedWithState:state];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (nullable id<LTTouchEventDelegate>)delegate {
  return self.stronglyHeldDelegate ?: self.weaklyHeldDelegate;
}

@end

NS_ASSUME_NONNULL_END
