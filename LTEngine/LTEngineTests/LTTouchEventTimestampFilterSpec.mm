// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventTimestampFilter.h"

#import <LTKit/NSObject+NSSet.h>

SpecBegin(LTTouchEventTimestampFilter)

__block LTTouchEventTimestampFilter *filter;
__block id<LTTouchEventDelegate> delegateMock;

beforeEach(^{
  delegateMock = OCMProtocolMock(@protocol(LTTouchEventDelegate));
  filter = [[LTTouchEventTimestampFilter alloc] initWithTouchEventDelegate:delegateMock];
});

afterEach(^{
  filter = nil;
  delegateMock = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(filter).toNot.beNil();
  });
});

context(@"touch event forwarding", ^{
  __block id<LTTouchEvent> touchEvent0;
  __block id<LTTouchEvent> touchEvent1;
  __block id<LTTouchEvent> touchEvent2;
  __block NSArray<id<LTTouchEvent>> *initialTouchEvents;
  __block NSArray<id<LTTouchEvent>> *touchEvents;
  __block NSArray<id<LTTouchEvent>> *predictedEvents;
  __block NSArray<id<LTTouchEvent>> *expectedTouchEvents;

  beforeEach(^{
    touchEvent0 = OCMProtocolMock(@protocol(LTTouchEvent));
    touchEvent1 = OCMProtocolMock(@protocol(LTTouchEvent));
    touchEvent2 = OCMProtocolMock(@protocol(LTTouchEvent));
    OCMStub([touchEvent0 timestamp]).andReturn(0.5);
    OCMStub([touchEvent1 timestamp]).andReturn(0.2);
    OCMStub([touchEvent2 timestamp]).andReturn(1);
    OCMStub([touchEvent0 sequenceID]).andReturn(7);
    OCMStub([touchEvent1 sequenceID]).andReturn(7);
    OCMStub([touchEvent2 sequenceID]).andReturn(7);
    initialTouchEvents = @[touchEvent0];
    touchEvents = @[touchEvent0, touchEvent1, touchEvent2];
    predictedEvents = @[];
    expectedTouchEvents = @[touchEvent0, touchEvent2];
  });

  afterEach(^{
    expectedTouchEvents = nil;
    predictedEvents = nil;
    touchEvents = nil;
    initialTouchEvents = nil;
    touchEvent2 = nil;
    touchEvent1 = nil;
    touchEvent0 = nil;
  });

  context(@"single touch event sequence", ^{
    context(@"forwarded calls", ^{
      it(@"should not filter the touch event of a starting touch event sequence", ^{
        [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
                     touchEventSequenceState:LTTouchEventSequenceStateStart];
        OCMVerify([delegateMock receivedTouchEvents:initialTouchEvents
                                    predictedEvents:predictedEvents
                            touchEventSequenceState:LTTouchEventSequenceStateStart]);
      });

      it(@"should forward calls to the receivedUpdatesOfTouchEvents: method", ^{
        [filter receivedUpdatesOfTouchEvents:touchEvents];
        OCMVerify([delegateMock receivedUpdatesOfTouchEvents:touchEvents]);
      });

      it(@"should forward calls to the sequence end method", ^{
        [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
            touchEventSequenceState:LTTouchEventSequenceStateStart];
        NSSet<NSNumber *> *sequenceIDs = [@7 lt_set];
        [filter touchEventSequencesWithIDs:sequenceIDs
                       terminatedWithState:LTTouchEventSequenceStateEnd];
        OCMVerify([delegateMock touchEventSequencesWithIDs:sequenceIDs
                                       terminatedWithState:LTTouchEventSequenceStateEnd]);
      });

      it(@"should forward calls to the sequence cancellation method", ^{
        [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
            touchEventSequenceState:LTTouchEventSequenceStateStart];
        NSSet<NSNumber *> *sequenceIDs = [@7 lt_set];
        [filter touchEventSequencesWithIDs:sequenceIDs
                       terminatedWithState:LTTouchEventSequenceStateCancellation];
        OCMVerify([delegateMock touchEventSequencesWithIDs:sequenceIDs
                                       terminatedWithState:LTTouchEventSequenceStateCancellation]);
      });
    });

    it(@"should forward continuing touch events with monotonically increasing timestamps",
       ^{
      [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateStart];
      [filter receivedTouchEvents:touchEvents predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateContinuation];
      OCMVerify([delegateMock receivedTouchEvents:expectedTouchEvents
                                  predictedEvents:predictedEvents
                          touchEventSequenceState:LTTouchEventSequenceStateContinuation]);
    });

    it(@"should forward stationary touch events with monotonically increasing timestamps",
       ^{
         [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
             touchEventSequenceState:LTTouchEventSequenceStateStart];
         [filter receivedTouchEvents:touchEvents predictedEvents:predictedEvents
             touchEventSequenceState:LTTouchEventSequenceStateContinuation];
         OCMVerify([delegateMock receivedTouchEvents:expectedTouchEvents
                                     predictedEvents:predictedEvents
                             touchEventSequenceState:LTTouchEventSequenceStateContinuation]);
       });

    it(@"should forward ending touch events with monotonically increasing timestamps", ^{
      [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateStart];
      [filter receivedTouchEvents:touchEvents predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateEnd];
      OCMVerify([delegateMock receivedTouchEvents:expectedTouchEvents
                                  predictedEvents:predictedEvents
                          touchEventSequenceState:LTTouchEventSequenceStateEnd]);
    });

    it(@"should provide cancelling touch events with monotonically increasing timestamps",
       ^{
      [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateStart];
      [filter receivedTouchEvents:touchEvents predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateCancellation];
      OCMVerify([delegateMock receivedTouchEvents:expectedTouchEvents
                                  predictedEvents:predictedEvents
                          touchEventSequenceState:LTTouchEventSequenceStateCancellation]);
    });

    it(@"should call correct delegate method for ending touch event sequence", ^{
      [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateStart];
      [filter receivedTouchEvents:@[touchEvent1]
                  predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateEnd];
      OCMExpect([delegateMock
                 touchEventSequencesWithIDs:[@7 lt_set]
                 terminatedWithState:LTTouchEventSequenceStateEnd]);
    });

    it(@"should call correct delegate method for cancelled touch event sequence", ^{
      [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateStart];
      [filter receivedTouchEvents:@[touchEvent1]
                  predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateCancellation];
      OCMExpect([delegateMock
                 touchEventSequencesWithIDs:[@7 lt_set]
                 terminatedWithState:LTTouchEventSequenceStateCancellation]);
    });
  });

  context(@"multiple touch event sequences", ^{
    __block id<LTTouchEvent> touchEventOfDifferentSequence0;
    __block id<LTTouchEvent> touchEventOfDifferentSequence1;
    __block id<LTTouchEvent> touchEventOfDifferentSequence2;
    __block NSArray<id<LTTouchEvent>> *initialTouchEventsOfDifferentSequence;
    __block NSArray<id<LTTouchEvent>> *touchEventsOfDifferentSequence;
    __block NSArray<id<LTTouchEvent>> *expectedTouchEventsOfDifferentSequence;

    beforeEach(^{
      touchEventOfDifferentSequence0 = OCMProtocolMock(@protocol(LTTouchEvent));
      touchEventOfDifferentSequence1 = OCMProtocolMock(@protocol(LTTouchEvent));
      touchEventOfDifferentSequence2 = OCMProtocolMock(@protocol(LTTouchEvent));
      OCMStub([touchEventOfDifferentSequence0 timestamp]).andReturn(0.8);
      OCMStub([touchEventOfDifferentSequence1 timestamp]).andReturn(0.1);
      OCMStub([touchEventOfDifferentSequence2 timestamp]).andReturn(0.9);
      OCMStub([touchEventOfDifferentSequence0 sequenceID]).andReturn(8);
      OCMStub([touchEventOfDifferentSequence1 sequenceID]).andReturn(8);
      OCMStub([touchEventOfDifferentSequence2 sequenceID]).andReturn(8);
      initialTouchEventsOfDifferentSequence = @[touchEventOfDifferentSequence0];
      touchEventsOfDifferentSequence = @[touchEventOfDifferentSequence0,
                                         touchEventOfDifferentSequence1,
                                         touchEventOfDifferentSequence2];
      expectedTouchEventsOfDifferentSequence = @[touchEventOfDifferentSequence0,
                                                 touchEventOfDifferentSequence2];
    });

    afterEach(^{
      touchEventsOfDifferentSequence = nil;
      initialTouchEventsOfDifferentSequence = nil;
      touchEventOfDifferentSequence2 = nil;
      touchEventOfDifferentSequence1 = nil;
      touchEventOfDifferentSequence0 = nil;
    });

    context(@"forwarded calls", ^{
      it(@"should not filter the touch event of starting touch event sequences", ^{
        [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
            touchEventSequenceState:LTTouchEventSequenceStateStart];
        OCMVerify([delegateMock receivedTouchEvents:initialTouchEvents
                                    predictedEvents:predictedEvents
                            touchEventSequenceState:LTTouchEventSequenceStateStart]);
        [filter receivedTouchEvents:initialTouchEventsOfDifferentSequence
                    predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
        OCMVerify([delegateMock receivedTouchEvents:initialTouchEventsOfDifferentSequence
                                    predictedEvents:@[]
                            touchEventSequenceState:LTTouchEventSequenceStateStart]);
      });

      it(@"should forward calls to the receivedUpdatesOfTouchEvents: method", ^{
        [filter receivedUpdatesOfTouchEvents:touchEvents];
        OCMVerify([delegateMock receivedUpdatesOfTouchEvents:touchEvents]);
        [filter receivedUpdatesOfTouchEvents:touchEventsOfDifferentSequence];
        OCMVerify([delegateMock receivedUpdatesOfTouchEvents:touchEventsOfDifferentSequence]);
      });

      it(@"should forward calls to the sequence end method", ^{
        [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
            touchEventSequenceState:LTTouchEventSequenceStateStart];
        [filter receivedTouchEvents:initialTouchEventsOfDifferentSequence
                    predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];

        NSSet<NSNumber *> *sequenceIDs = [@[@7, @8] lt_set];
        [filter touchEventSequencesWithIDs:sequenceIDs
                       terminatedWithState:LTTouchEventSequenceStateEnd];
        OCMVerify([delegateMock touchEventSequencesWithIDs:sequenceIDs
                                       terminatedWithState:LTTouchEventSequenceStateEnd]);
      });

      it(@"should forward consecutive calls to the sequence end method", ^{
        [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
            touchEventSequenceState:LTTouchEventSequenceStateStart];
        [filter receivedTouchEvents:initialTouchEventsOfDifferentSequence
                    predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];

        NSSet<NSNumber *> *sequenceIDs = [@7 lt_set];
        [filter touchEventSequencesWithIDs:sequenceIDs
                       terminatedWithState:LTTouchEventSequenceStateEnd];
        OCMVerify([delegateMock touchEventSequencesWithIDs:sequenceIDs
                                       terminatedWithState:LTTouchEventSequenceStateEnd]);
        sequenceIDs = [@8 lt_set];
        [filter touchEventSequencesWithIDs:sequenceIDs
                       terminatedWithState:LTTouchEventSequenceStateEnd];
        OCMVerify([delegateMock touchEventSequencesWithIDs:sequenceIDs
                                       terminatedWithState:LTTouchEventSequenceStateEnd]);
      });

      it(@"should forward calls to the sequence cancellation method", ^{
        [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
            touchEventSequenceState:LTTouchEventSequenceStateStart];
        [filter receivedTouchEvents:initialTouchEventsOfDifferentSequence
                    predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];

        NSSet<NSNumber *> *sequenceIDs = [@[@7, @8] lt_set];
        [filter touchEventSequencesWithIDs:sequenceIDs
                       terminatedWithState:LTTouchEventSequenceStateCancellation];
        OCMVerify([delegateMock touchEventSequencesWithIDs:sequenceIDs
                                       terminatedWithState:LTTouchEventSequenceStateCancellation]);
      });

      it(@"should forward consecutive calls to the sequence cancellation method", ^{
        [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
            touchEventSequenceState:LTTouchEventSequenceStateStart];
        [filter receivedTouchEvents:initialTouchEventsOfDifferentSequence
                    predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];

        NSSet<NSNumber *> *sequenceIDs = [@7 lt_set];
        [filter touchEventSequencesWithIDs:sequenceIDs
                       terminatedWithState:LTTouchEventSequenceStateCancellation];
        OCMVerify([delegateMock touchEventSequencesWithIDs:sequenceIDs
                                       terminatedWithState:LTTouchEventSequenceStateCancellation]);

        sequenceIDs = [@8 lt_set];
        [filter touchEventSequencesWithIDs:sequenceIDs
                       terminatedWithState:LTTouchEventSequenceStateCancellation];
        OCMVerify([delegateMock touchEventSequencesWithIDs:sequenceIDs
                                       terminatedWithState:LTTouchEventSequenceStateCancellation]);
      });
    });

    it(@"should forward continuing touch events with monotonically increasing timestamps", ^{
         [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
             touchEventSequenceState:LTTouchEventSequenceStateStart];
         [filter receivedTouchEvents:initialTouchEventsOfDifferentSequence
                     predictedEvents:@[]
             touchEventSequenceState:LTTouchEventSequenceStateStart];

         [filter receivedTouchEvents:touchEvents predictedEvents:predictedEvents
             touchEventSequenceState:LTTouchEventSequenceStateContinuation];
         OCMVerify([delegateMock receivedTouchEvents:expectedTouchEvents
                                     predictedEvents:predictedEvents
                             touchEventSequenceState:LTTouchEventSequenceStateContinuation]);

         [filter receivedTouchEvents:touchEventsOfDifferentSequence
                     predictedEvents:@[]
             touchEventSequenceState:LTTouchEventSequenceStateContinuation];
         OCMVerify([delegateMock receivedTouchEvents:expectedTouchEventsOfDifferentSequence
                                     predictedEvents:predictedEvents
                             touchEventSequenceState:LTTouchEventSequenceStateContinuation]);
       });

    it(@"should forward stationary touch events with monotonically increasing timestamps", ^{
      [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateStart];
      [filter receivedTouchEvents:initialTouchEventsOfDifferentSequence
                  predictedEvents:@[]
          touchEventSequenceState:LTTouchEventSequenceStateStart];

      [filter receivedTouchEvents:touchEvents predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary];
      OCMVerify([delegateMock receivedTouchEvents:expectedTouchEvents
                                  predictedEvents:predictedEvents
                          touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary]);

      [filter receivedTouchEvents:touchEventsOfDifferentSequence
                  predictedEvents:@[]
          touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary];
      OCMVerify([delegateMock receivedTouchEvents:expectedTouchEventsOfDifferentSequence
                                  predictedEvents:@[]
                          touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary]);
    });

    it(@"should forward ending touch events with monotonically increasing timestamps", ^{
      [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateStart];
      [filter receivedTouchEvents:initialTouchEventsOfDifferentSequence predictedEvents:@[]
          touchEventSequenceState:LTTouchEventSequenceStateStart];

      [filter receivedTouchEvents:touchEvents predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateEnd];
      OCMVerify([delegateMock receivedTouchEvents:expectedTouchEvents
                                  predictedEvents:predictedEvents
                          touchEventSequenceState:LTTouchEventSequenceStateEnd]);

      [filter receivedTouchEvents:touchEventsOfDifferentSequence predictedEvents:@[]
          touchEventSequenceState:LTTouchEventSequenceStateEnd];
      OCMVerify([delegateMock receivedTouchEvents:expectedTouchEventsOfDifferentSequence
                                  predictedEvents:@[]
                          touchEventSequenceState:LTTouchEventSequenceStateEnd]);
    });

    it(@"should provide cancelling touch events with monotonically increasing timestamps", ^{
    [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
        touchEventSequenceState:LTTouchEventSequenceStateStart];
    [filter receivedTouchEvents:initialTouchEventsOfDifferentSequence predictedEvents:@[]
        touchEventSequenceState:LTTouchEventSequenceStateStart];

    [filter receivedTouchEvents:touchEvents predictedEvents:predictedEvents
        touchEventSequenceState:LTTouchEventSequenceStateCancellation];
    OCMVerify([delegateMock receivedTouchEvents:expectedTouchEvents
                                predictedEvents:predictedEvents
                        touchEventSequenceState:LTTouchEventSequenceStateCancellation]);

    [filter receivedTouchEvents:touchEventsOfDifferentSequence predictedEvents:@[]
        touchEventSequenceState:LTTouchEventSequenceStateCancellation];
    OCMVerify([delegateMock receivedTouchEvents:expectedTouchEventsOfDifferentSequence
                                predictedEvents:@[]
                        touchEventSequenceState:LTTouchEventSequenceStateCancellation]);
    });

    it(@"should call correct delegate method for ending touch event sequence", ^{
      [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateStart];
      [filter receivedTouchEvents:initialTouchEventsOfDifferentSequence predictedEvents:@[]
          touchEventSequenceState:LTTouchEventSequenceStateStart];

      [filter receivedTouchEvents:@[touchEvent1]
                  predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateEnd];
      OCMExpect([delegateMock
                 touchEventSequencesWithIDs:[@7 lt_set]
                 terminatedWithState:LTTouchEventSequenceStateEnd]);

      [filter receivedTouchEvents:@[touchEventOfDifferentSequence1]
                  predictedEvents:@[]
          touchEventSequenceState:LTTouchEventSequenceStateEnd];
      OCMExpect([delegateMock
                 touchEventSequencesWithIDs:[@8 lt_set]
                 terminatedWithState:LTTouchEventSequenceStateEnd]);
    });

    it(@"should call correct delegate method for cancelled touch event sequence", ^{
      [filter receivedTouchEvents:initialTouchEvents predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateStart];
      [filter receivedTouchEvents:initialTouchEventsOfDifferentSequence predictedEvents:@[]
          touchEventSequenceState:LTTouchEventSequenceStateStart];

      [filter receivedTouchEvents:@[touchEvent1]
                  predictedEvents:predictedEvents
          touchEventSequenceState:LTTouchEventSequenceStateCancellation];
      OCMExpect([delegateMock
                 touchEventSequencesWithIDs:[@7 lt_set]
                 terminatedWithState:LTTouchEventSequenceStateCancellation]);

      [filter receivedTouchEvents:@[touchEventOfDifferentSequence1]
                  predictedEvents:@[]
          touchEventSequenceState:LTTouchEventSequenceStateCancellation];
      OCMExpect([delegateMock
                 touchEventSequencesWithIDs:[@7 lt_set]
                 terminatedWithState:LTTouchEventSequenceStateCancellation]);
    });
  });
});

SpecEnd
