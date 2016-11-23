// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventTimestampFilter.h"

NS_ASSUME_NONNULL_BEGIN

// TODO:(rouven) Remove this filter once the bug has been fixed by Apple (radar number 29139098).
@interface LTTouchEventTimestampFilter ()

/// Mapping of IDs of \c id<LTTouchEvent> sequences to the most recent \c timestamp of the
/// \c id<LTTouchEvent> objects per sequence.
@property (readonly, nonatomic) NSMutableDictionary<NSNumber *, NSNumber *> *sequenceIDToTimestamp;

@end

@implementation LTTouchEventTimestampFilter

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithTouchEventDelegate:(id<LTTouchEventDelegate>)delegate {
  LTParameterAssert(delegate);

  if (self = [super init]) {
    _delegate = delegate;
    _sequenceIDToTimestamp = [NSMutableDictionary dictionary];
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

  if (state == LTTouchEventSequenceStateStart) {
    [self forwardStartingTouchEvents:touchEvents predictedEvents:predictedTouchEvents];
    return;
  }

  LTTouchEvents *filteredTouchEvents = [self filteredTouchEventsFromTouchEvents:touchEvents];

  BOOL isTerminatingState =
      state == LTTouchEventSequenceStateEnd || state == LTTouchEventSequenceStateCancellation;
  NSNumber *sequenceID = @(touchEvents.firstObject.sequenceID);

  if (isTerminatingState) {
    [self.sequenceIDToTimestamp removeObjectForKey:sequenceID];
  }

  if (filteredTouchEvents.count) {
    [self.delegate receivedTouchEvents:filteredTouchEvents predictedEvents:predictedTouchEvents
               touchEventSequenceState:state];
  } else if (isTerminatingState) {
    NSSet<NSNumber *> *sequenceIDs = [NSSet setWithObject:sequenceID];
    [self.delegate touchEventSequencesWithIDs:sequenceIDs terminatedWithState:state];
  }
}

- (void)forwardStartingTouchEvents:(LTTouchEvents *)touchEvents
                   predictedEvents:(LTTouchEvents *)predictedTouchEvents {
  NSUInteger sequenceID = touchEvents.firstObject.sequenceID;

  LTAssert(!self.sequenceIDToTimestamp[@(sequenceID)],
           @"Entry for sequence with ID %lu already exists", (unsigned long)sequenceID);
  self.sequenceIDToTimestamp[@(sequenceID)] = @(touchEvents.firstObject.timestamp);

  [self.delegate receivedTouchEvents:touchEvents predictedEvents:predictedTouchEvents
             touchEventSequenceState:LTTouchEventSequenceStateStart];
}

- (LTTouchEvents *)filteredTouchEventsFromTouchEvents:(LTTouchEvents *)touchEvents {
  NSUInteger sequenceID = touchEvents.firstObject.sequenceID;

  LTAssert(self.sequenceIDToTimestamp[@(sequenceID)],
           @"Entry for sequence with ID %lu does not exist", (unsigned long)sequenceID);

  NSTimeInterval timestamp = self.sequenceIDToTimestamp[@(sequenceID)].doubleValue;

  NSMutableArray<id<LTTouchEvent>> *filteredTouchEvents = [NSMutableArray array];

  for (id<LTTouchEvent> touchEvent in touchEvents) {
    if (touchEvent.timestamp < timestamp) {
      continue;
    }
    [filteredTouchEvents addObject:touchEvent];
    timestamp = touchEvent.timestamp;
  }

  self.sequenceIDToTimestamp[@(sequenceID)] = @(timestamp);

  return [filteredTouchEvents copy];
}

- (void)receivedUpdatesOfTouchEvents:(LTTouchEvents *)touchEvents {
  LTParameterAssert(touchEvents.count);
  [self.delegate receivedUpdatesOfTouchEvents:touchEvents];
}

- (void)touchEventSequencesWithIDs:(NSSet<NSNumber *> *)sequenceIDs
               terminatedWithState:(LTTouchEventSequenceState)state {
  LTParameterAssert(sequenceIDs.count);

  for (NSNumber *sequenceID in sequenceIDs) {
    LTAssert(self.sequenceIDToTimestamp[sequenceID],
             @"Entry for sequence with ID %lu does not exist",
             (unsigned long)sequenceID.unsignedIntegerValue);
    [self.sequenceIDToTimestamp removeObjectForKey:sequenceID];
  }

  [self.delegate touchEventSequencesWithIDs:sequenceIDs terminatedWithState:state];
}

@end

NS_ASSUME_NONNULL_END
