// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventSequenceSplitter.h"

SpecBegin(LTTouchEventSequenceSplitter)

__block id<LTTouchEventDelegate> delegateMock;
__block LTTouchEventSequenceSplitter *splitter;

beforeEach(^{
  delegateMock = OCMProtocolMock(@protocol(LTTouchEventDelegate));
  splitter = [[LTTouchEventSequenceSplitter alloc] initWithTouchEventDelegate:delegateMock];
});

afterEach(^{
  splitter = nil;
  delegateMock = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(splitter).toNot.beNil();
  });
});

context(@"forwarding", ^{
  __block LTTouchEvents *singleTouchEvent;
  __block LTTouchEvents *severalTouchEvents;
  __block LTTouchEvents *predictedTouchEvents;

  beforeEach(^{
    singleTouchEvent = @[OCMProtocolMock(@protocol(LTTouchEvent))];
    severalTouchEvents = @[OCMProtocolMock(@protocol(LTTouchEvent)),
                           OCMProtocolMock(@protocol(LTTouchEvent)),
                           OCMProtocolMock(@protocol(LTTouchEvent))];
    predictedTouchEvents = @[OCMProtocolMock(@protocol(LTTouchEvent))];
  });

  afterEach(^{
    predictedTouchEvents = nil;
    severalTouchEvents = nil;
    singleTouchEvent = nil;
  });

  context(@"forwarding without changes", ^{
    it(@"should forward starting touch event sequences without any change", ^{
      OCMExpect([delegateMock receivedTouchEvents:severalTouchEvents
                                  predictedEvents:predictedTouchEvents
                          touchEventSequenceState:LTTouchEventSequenceStateStart]);

      [splitter receivedTouchEvents:severalTouchEvents predictedEvents:predictedTouchEvents
            touchEventSequenceState:LTTouchEventSequenceStateStart];

      OCMVerifyAll(delegateMock);
    });

    it(@"should forward continuing touch event sequences without any change", ^{
      OCMExpect([delegateMock receivedTouchEvents:severalTouchEvents
                                  predictedEvents:predictedTouchEvents
                          touchEventSequenceState:LTTouchEventSequenceStateContinuation]);

      [splitter receivedTouchEvents:severalTouchEvents predictedEvents:predictedTouchEvents
            touchEventSequenceState:LTTouchEventSequenceStateContinuation];

      OCMVerifyAll(delegateMock);
    });

    it(@"should forward stationary touch event sequences without any change", ^{
      OCMExpect([delegateMock receivedTouchEvents:severalTouchEvents
                                  predictedEvents:predictedTouchEvents
                          touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary]);

      [splitter receivedTouchEvents:severalTouchEvents predictedEvents:predictedTouchEvents
            touchEventSequenceState:LTTouchEventSequenceStateContinuationStationary];

      OCMVerifyAll(delegateMock);
    });
  });

  context(@"forwarding with changes", ^{
    context(@"single touch event", ^{
      it(@"should forward ending touch event sequences without predicted touch events", ^{
        OCMExpect([delegateMock receivedTouchEvents:singleTouchEvent predictedEvents:@[]
                            touchEventSequenceState:LTTouchEventSequenceStateEnd]);

        [splitter receivedTouchEvents:singleTouchEvent predictedEvents:predictedTouchEvents
              touchEventSequenceState:LTTouchEventSequenceStateEnd];

        OCMVerifyAll(delegateMock);
      });

      it(@"should forward cancelled touch event sequences without predicted touch events", ^{
        OCMExpect([delegateMock receivedTouchEvents:singleTouchEvent predictedEvents:@[]
                            touchEventSequenceState:LTTouchEventSequenceStateCancellation]);

        [splitter receivedTouchEvents:singleTouchEvent predictedEvents:predictedTouchEvents
              touchEventSequenceState:LTTouchEventSequenceStateCancellation];

        OCMVerifyAll(delegateMock);
      });
    });

    context(@"several touch events", ^{
      beforeEach(^{
        [(id)delegateMock setExpectationOrderMatters:YES];
      });

      it(@"should forward ending touch event sequences in two separate calls", ^{
        NSRange range = NSMakeRange(0, severalTouchEvents.count - 1);
        OCMExpect([delegateMock receivedTouchEvents:[severalTouchEvents subarrayWithRange:range]
                                    predictedEvents:@[]
                            touchEventSequenceState:LTTouchEventSequenceStateContinuation]);
        OCMExpect([delegateMock receivedTouchEvents:@[severalTouchEvents.lastObject]
                                    predictedEvents:@[]
                            touchEventSequenceState:LTTouchEventSequenceStateEnd]);

        [splitter receivedTouchEvents:severalTouchEvents predictedEvents:predictedTouchEvents
              touchEventSequenceState:LTTouchEventSequenceStateEnd];

        OCMVerifyAll(delegateMock);
      });

      it(@"should forward cancelling touch event sequences in two separate calls", ^{
        NSRange range = NSMakeRange(0, severalTouchEvents.count - 1);
        OCMExpect([delegateMock receivedTouchEvents:[severalTouchEvents subarrayWithRange:range]
                                    predictedEvents:@[]
                            touchEventSequenceState:LTTouchEventSequenceStateContinuation]);
        OCMExpect([delegateMock receivedTouchEvents:@[severalTouchEvents.lastObject]
                                    predictedEvents:@[]
                            touchEventSequenceState:LTTouchEventSequenceStateCancellation]);

        [splitter receivedTouchEvents:severalTouchEvents predictedEvents:predictedTouchEvents
              touchEventSequenceState:LTTouchEventSequenceStateCancellation];

        OCMVerifyAll(delegateMock);
      });
    });
  });
});

SpecEnd
