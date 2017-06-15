// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventSequenceValidatorExamples.h"

#import "LTTouchEvent.h"
#import "LTTouchEventDelegate.h"

NSString * const kLTTouchEventSequenceValidatorExamples = @"LTTouchEventSequenceValidatorExamples";

NSString * const kLTTouchEventSequenceValidatorExamplesDelegate =
    @"LTTouchEventSequenceValidatorExamplesDelegate";

SharedExamplesBegin(LTTouchEventSequenceValidatorExamples)

sharedExamplesFor(kLTTouchEventSequenceValidatorExamples, ^(NSDictionary *data) {
  __block id<LTTouchEventDelegate> delegate;
  __block id<LTTouchEvent> touchEvent0;
  __block id<LTTouchEvent> touchEvent1;
  __block id<LTTouchEvent> touchEvent2;
  __block NSArray<id<LTTouchEvent>> *touchEvents;
  __block NSArray<id<LTTouchEvent>> *predictedEvents;

  beforeEach(^{
    delegate = data[kLTTouchEventSequenceValidatorExamplesDelegate];
    touchEvent0 = OCMProtocolMock(@protocol(LTTouchEvent));
    touchEvent1 = OCMProtocolMock(@protocol(LTTouchEvent));
    touchEvent2 = OCMProtocolMock(@protocol(LTTouchEvent));
    OCMStub([touchEvent0 timestamp]).andReturn(0.2);
    OCMStub([touchEvent1 timestamp]).andReturn(0.5);
    OCMStub([touchEvent2 timestamp]).andReturn(1);
    OCMStub([touchEvent0 sequenceID]).andReturn(0);
    OCMStub([touchEvent1 sequenceID]).andReturn(0);
    OCMStub([touchEvent2 sequenceID]).andReturn(1);
    touchEvents = @[touchEvent0];
    predictedEvents = @[];
  });

  afterEach(^{
    predictedEvents = nil;
    touchEvents = nil;
    touchEvent2 = nil;
    touchEvent1 = nil;
    touchEvent0 = nil;
    delegate = nil;
  });

  context(@"number of touch events", ^{
    context(@"no touch events/sequence IDs", ^{
      it(@"should raise when receiving starting touch event sequence without touch events", ^{
        expect(^{
          [delegate receivedTouchEvents:@[] predictedEvents:@[]
                touchEventSequenceState:LTTouchEventSequenceStateStart];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving continuing touch event sequence without touch events", ^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
        expect(^{
          [delegate receivedTouchEvents:@[] predictedEvents:@[]
                touchEventSequenceState:LTTouchEventSequenceStateContinuation];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving stationary touch event sequence without touch events", ^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
        expect(^{
          [delegate receivedTouchEvents:@[] predictedEvents:@[]
                touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving ending touch event sequence without touch events", ^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
        expect(^{
          [delegate receivedTouchEvents:@[] predictedEvents:@[]
                touchEventSequenceState:LTTouchEventSequenceStateEnd];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving cancelled touch event sequence without touch events", ^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
        expect(^{
          [delegate receivedTouchEvents:@[] predictedEvents:@[]
                touchEventSequenceState:LTTouchEventSequenceStateCancellation];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving updates of zero touch events", ^{
        expect(^{
          [delegate receivedUpdatesOfTouchEvents:@[]];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving information about ended touch event sequences without IDs",
         ^{
        expect(^{
          [delegate touchEventSequencesWithIDs:[NSSet set]
                           terminatedWithState:LTTouchEventSequenceStateEnd];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving information about ended touch event sequences without IDs",
         ^{
        expect(^{
          [delegate touchEventSequencesWithIDs:[NSSet set]
                           terminatedWithState:LTTouchEventSequenceStateCancellation];
        }).to.raise(NSInvalidArgumentException);
      });
    });

    context(@"invalid number of touch events", ^{
      it(@"should raise when invoking with starting sequence containing more than one event", ^{
        expect(^{
          [delegate receivedTouchEvents:@[touchEvent0, touchEvent1] predictedEvents:@[]
                touchEventSequenceState:LTTouchEventSequenceStateStart];
        }).to.raise(NSInvalidArgumentException);
      });
    });
  });

  context(@"sequence IDs", ^{
    it(@"should raise when receiving starting sequence of events with invalid sequence IDs", ^{
      expect(^{
        [delegate receivedTouchEvents:@[touchEvent0, touchEvent2] predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when receiving continuing sequence of events with invalid sequence IDs", ^{
         [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
               touchEventSequenceState:LTTouchEventSequenceStateStart];
         expect(^{
           [delegate receivedTouchEvents:@[touchEvent2] predictedEvents:@[]
                 touchEventSequenceState:LTTouchEventSequenceStateContinuation];
         }).to.raise(NSInvalidArgumentException);
       });

    it(@"should raise when receiving stationary sequence of events with invalid sequence IDs", ^{
         [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
               touchEventSequenceState:LTTouchEventSequenceStateStart];
         expect(^{
           [delegate receivedTouchEvents:@[touchEvent2] predictedEvents:@[]
                 touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary];
         }).to.raise(NSInvalidArgumentException);
       });

    it(@"should raise when receiving ending sequence of events with invalid sequence IDs", ^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
      expect(^{
        [delegate receivedTouchEvents:@[touchEvent2] predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateEnd];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when receiving cancelled sequence of events with invalid sequence IDs", ^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
      expect(^{
        [delegate receivedTouchEvents:@[touchEvent2] predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateCancellation];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"order of touch events according to timestamps", ^{
    context(@"touch events", ^{
      it(@"should raise when receiving starting sequence of incorrectly ordered events", ^{
        expect(^{
          [delegate receivedTouchEvents:@[touchEvent1, touchEvent0] predictedEvents:@[]
                touchEventSequenceState:LTTouchEventSequenceStateStart];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving continuing sequence of incorrectly ordered events", ^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
        expect(^{
          [delegate receivedTouchEvents:@[touchEvent1, touchEvent0] predictedEvents:@[]
                touchEventSequenceState:LTTouchEventSequenceStateContinuation];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving stationary sequence of incorrectly ordered events", ^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
        expect(^{
          [delegate receivedTouchEvents:@[touchEvent1, touchEvent0] predictedEvents:@[]
                touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving ending sequence of incorrectly ordered events", ^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
        expect(^{
          [delegate receivedTouchEvents:@[touchEvent1, touchEvent0] predictedEvents:@[]
                touchEventSequenceState:LTTouchEventSequenceStateEnd];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving cancelled sequence of incorrectly ordered events", ^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
        expect(^{
          [delegate receivedTouchEvents:@[touchEvent1, touchEvent0] predictedEvents:@[]
                touchEventSequenceState:LTTouchEventSequenceStateCancellation];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving updates of incorrectly ordered touch events", ^{
        expect(^{
          [delegate receivedUpdatesOfTouchEvents:@[touchEvent1, touchEvent1]];
        }).to.raise(NSInvalidArgumentException);
      });
    });

    context(@"predicted touch events", ^{
      it(@"should raise when receiving starting sequence of incorrectly ordered predicted events",
         ^{
        expect(^{
          [delegate receivedTouchEvents:touchEvents predictedEvents:@[touchEvent1, touchEvent0]
                touchEventSequenceState:LTTouchEventSequenceStateStart];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving continuing sequence of incorrectly ordered predicted events",
         ^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
        expect(^{
          [delegate receivedTouchEvents:touchEvents predictedEvents:@[touchEvent1, touchEvent0]
                touchEventSequenceState:LTTouchEventSequenceStateContinuation];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving stationary sequence of incorrectly ordered predicted events",
         ^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
        expect(^{
          [delegate receivedTouchEvents:touchEvents predictedEvents:@[touchEvent1, touchEvent0]
                touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving ending sequence of incorrectly ordered predicted events", ^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
        expect(^{
          [delegate receivedTouchEvents:touchEvents predictedEvents:@[touchEvent1, touchEvent0]
                touchEventSequenceState:LTTouchEventSequenceStateEnd];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when receiving cancelled sequence of incorrectly ordered predicted events",
         ^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
        expect(^{
          [delegate receivedTouchEvents:touchEvents predictedEvents:@[touchEvent1, touchEvent0]
                touchEventSequenceState:LTTouchEventSequenceStateCancellation];
        }).to.raise(NSInvalidArgumentException);
      });
    });
  });

  context(@"invalid order of method invocations", ^{
    it(@"should raise when being informed about start of sequence after already starting", ^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
      expect(^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when being informed about start of sequence after its continuation", ^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateContinuation];
      expect(^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when being informed about start of sequence after stationary state", ^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary];
      expect(^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when receiving continuation sequence without receiving starting sequence", ^{
      expect(^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateContinuation];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when receiving stationary sequence without receiving starting sequence", ^{
      expect(^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when receiving ending sequence without receiving starting sequence", ^{
      expect(^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateEnd];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when receiving cancelled sequence without receiving starting sequence", ^{
      expect(^{
        [delegate touchEventSequencesWithIDs:[NSSet setWithObject:@0]
                         terminatedWithState:LTTouchEventSequenceStateCancellation];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when receiving update sequence without receiving starting sequence", ^{
      expect(^{
        [delegate receivedUpdatesOfTouchEvents:touchEvents];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when receiving end information without receiving starting sequence", ^{
      expect(^{
        [delegate touchEventSequencesWithIDs:[NSSet setWithObject:@0]
                         terminatedWithState:LTTouchEventSequenceStateEnd];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when receiving cancellation information without receiving starting sequence",
       ^{
      expect(^{
        [delegate touchEventSequencesWithIDs:[NSSet setWithObject:@0]
                         terminatedWithState:LTTouchEventSequenceStateCancellation];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when being informed about end of sequence after its end", ^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateEnd];
      expect(^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateEnd];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when being informed about cancellation of sequence after its end", ^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateEnd];
      expect(^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateCancellation];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when being informed about cancellation of sequence after its cancellation", ^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateCancellation];
      expect(^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateCancellation];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when being informed about end of sequence after its cancellation", ^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateCancellation];
      expect(^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateEnd];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when being informed about end of an already ended sequence", ^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateEnd];
      expect(^{
        [delegate touchEventSequencesWithIDs:[NSSet setWithObject:@0]
                         terminatedWithState:LTTouchEventSequenceStateEnd];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when being informed about cancellation of already ended sequence", ^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateEnd];
      expect(^{
        [delegate touchEventSequencesWithIDs:[NSSet setWithObject:@0]
                         terminatedWithState:LTTouchEventSequenceStateCancellation];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when being informed about cancellation of already cancelled sequence", ^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateCancellation];
      expect(^{
        [delegate touchEventSequencesWithIDs:[NSSet setWithObject:@0]
                         terminatedWithState:LTTouchEventSequenceStateCancellation];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when being informed about end of already cancelled sequence", ^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateCancellation];
      expect(^{
        [delegate touchEventSequencesWithIDs:[NSSet setWithObject:@0]
                         terminatedWithState:LTTouchEventSequenceStateEnd];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"invalid state for termination method", ^{
    beforeEach(^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
    });

    it(@"should raise when invoking termination method with start state", ^{
      expect(^{
        [delegate touchEventSequencesWithIDs:[NSSet setWithObject:@0]
                         terminatedWithState:LTTouchEventSequenceStateStart];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when invoking termination method with continuation state", ^{
      expect(^{
        [delegate touchEventSequencesWithIDs:[NSSet setWithObject:@0]
                         terminatedWithState:LTTouchEventSequenceStateContinuation];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when invoking termination method with stationary state", ^{
      expect(^{
        [delegate touchEventSequencesWithIDs:[NSSet setWithObject:@0]
                         terminatedWithState:LTTouchEventSequenceStateContinuationStationary];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"valid calls", ^{
    it(@"should not raise when providing consecutive touch event sequences with same ID", ^{
      [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
            touchEventSequenceState:LTTouchEventSequenceStateStart];
      [delegate touchEventSequencesWithIDs:[NSSet setWithObject:@0]
                       terminatedWithState:LTTouchEventSequenceStateEnd];
      expect(^{
        [delegate receivedTouchEvents:touchEvents predictedEvents:@[]
              touchEventSequenceState:LTTouchEventSequenceStateStart];
        [delegate touchEventSequencesWithIDs:[NSSet setWithObject:@0]
                         terminatedWithState:LTTouchEventSequenceStateEnd];
      }).toNot.raise(NSInvalidArgumentException);
    });
  });
});

SharedExamplesEnd
