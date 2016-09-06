// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventSequenceSplitter.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTTouchEventSequenceSplitter

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithTouchEventDelegate:(id<LTTouchEventDelegate>)delegate {
  LTParameterAssert(delegate);

  if (self = [super init]) {
    _delegate = delegate;
  }
  return self;
}

#pragma mark -
#pragma mark LTTouchEventDelegate
#pragma mark -

- (void)receivedTouchEvents:(LTTouchEvents *)touchEvents
            predictedEvents:(LTTouchEvents *)predictedTouchEvents
    touchEventSequenceState:(LTTouchEventSequenceState)state {
  BOOL terminatingState = state == LTTouchEventSequenceStateEnd ||
      state == LTTouchEventSequenceStateCancellation;

  if (touchEvents.count < 2 || !terminatingState) {
    [self.delegate receivedTouchEvents:touchEvents
                       predictedEvents:terminatingState ? @[] : predictedTouchEvents
               touchEventSequenceState:state];
    return;
  }

  NSRange range = NSMakeRange(0, touchEvents.count - 1);
  [self.delegate receivedTouchEvents:[touchEvents subarrayWithRange:range] predictedEvents:@[]
             touchEventSequenceState:LTTouchEventSequenceStateContinuation];
  [self.delegate receivedTouchEvents:@[touchEvents.lastObject] predictedEvents:@[]
             touchEventSequenceState:state];
}

- (void)receivedUpdatesOfTouchEvents:(LTTouchEvents *)touchEvents {
  [self.delegate receivedUpdatesOfTouchEvents:touchEvents];
}

- (void)touchEventSequencesWithIDs:(NSSet<NSNumber *> *)sequenceIDs
               terminatedWithState:(LTTouchEventSequenceState)state {
  [self.delegate touchEventSequencesWithIDs:sequenceIDs terminatedWithState:state];
}

@end

NS_ASSUME_NONNULL_END
