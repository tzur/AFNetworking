// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventStateFilter.h"

#import "LTContentTouchEventFilter.h"
#import "LTContentTouchEventPredicate.h"

static LTContentTouchEvents *LTContentTouchEventMocks(NSUInteger count) {
  LTMutableContentTouchEvents *events = [NSMutableArray array];
  for (NSUInteger i = 0; i < count; ++i) {
    [events addObject:OCMProtocolMock(@protocol(LTContentTouchEvent))];
  }
  return [events copy];
}

// These are used to verify that when the filter is back to idle state it's entire state is
// identical to its state after initialization.
@interface LTContentTouchEventStateFilter ()
@property (strong, nonatomic, nullable) id<LTContentTouchEvent> sequenceInitialTouchEvent;
@property (strong, nonatomic, nullable) LTContentTouchEventFilter *eventsFilter;
@end

SpecBegin(LTContentTouchEventStateFilter)

__block id<LTContentTouchEventPredicate> possiblePredicate;
__block id<LTContentTouchEventPredicate> activePredicate;

beforeEach(^{
  possiblePredicate = OCMProtocolMock(@protocol(LTContentTouchEventPredicate));
  activePredicate = OCMProtocolMock(@protocol(LTContentTouchEventPredicate));
});

afterEach(^{
  possiblePredicate = nil;
  activePredicate = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    LTContentTouchEventStateFilter *filter =
        [[LTContentTouchEventStateFilter alloc] initWithPredicateForPossibleState:possiblePredicate
                                                          predicateForActiveState:activePredicate];

    expect(filter.predicateForPossibleState).to.equal(possiblePredicate);
    expect(filter.predicateForActiveState).to.equal(activePredicate);

    expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStateIdle);
    expect(filter.sequenceInitialTouchEvent).to.beNil();
    expect(filter.eventsFilter).to.beNil();
  });
});

context(@"filtering", ^{
  __block LTContentTouchEventStateFilter *filter;

  beforeEach(^{
    filter = [[LTContentTouchEventStateFilter alloc]
              initWithPredicateForPossibleState:possiblePredicate
              predicateForActiveState:activePredicate];
  });

  context(@"idle state", ^{
    beforeEach(^{
      OCMReject([possiblePredicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]);
      OCMReject([activePredicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]);
    });

    it(@"should not filter event with LTTouchEventSequenceStateStart regardless of predicates", ^{
      LTContentTouchEvents *events = LTContentTouchEventMocks(1);
      LTContentTouchEvents *filteredEvents =
          [filter filterContentTouchEvents:events
                    withTouchSequenceState:LTTouchEventSequenceStateStart];
      expect(filteredEvents).to.haveCountOf(1);
      expect(filteredEvents.firstObject).to.beIdenticalTo(events.firstObject);
    });

    it(@"should change state when receiving a single event with LTTouchEventSequenceStateStart", ^{
      [filter filterContentTouchEvents:LTContentTouchEventMocks(1)
                withTouchSequenceState:LTTouchEventSequenceStateStart];
      expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStatePossible);
    });

    it(@"should raise if receives zero events with LTTouchEventSequenceStateStart", ^{
      expect(^{
        [filter filterContentTouchEvents:@[] withTouchSequenceState:LTTouchEventSequenceStateStart];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise if receives multiple events with LTTouchEventSequenceStateStart", ^{
      expect(^{
        [filter filterContentTouchEvents:LTContentTouchEventMocks(2)
                  withTouchSequenceState:LTTouchEventSequenceStateStart];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise if receives event with a different state", ^{
      expect(^{
        [filter filterContentTouchEvents:LTContentTouchEventMocks(1)
                  withTouchSequenceState:LTTouchEventSequenceStateContinuation];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [filter filterContentTouchEvents:LTContentTouchEventMocks(1)
                  withTouchSequenceState:LTTouchEventSequenceStateContinuationStationary];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [filter filterContentTouchEvents:LTContentTouchEventMocks(1)
                  withTouchSequenceState:LTTouchEventSequenceStateEnd];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        [filter filterContentTouchEvents:LTContentTouchEventMocks(1)
                  withTouchSequenceState:LTTouchEventSequenceStateCancellation];
      }).to.raise(NSInvalidArgumentException);

      it(@"should do nothing in case cancelActiveSequence is called", ^{
        [filter cancelActiveSequence];
        expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStateIdle);
        expect(filter.sequenceInitialTouchEvent).to.beNil();
        expect(filter.eventsFilter).to.beNil();
      });
    });
  });

  context(@"possible state", ^{
    __block id<LTContentTouchEvent> firstEvent;

    beforeEach(^{
      firstEvent = OCMProtocolMock(@protocol(LTContentTouchEvent));
      [filter filterContentTouchEvents:@[firstEvent]
                withTouchSequenceState:LTTouchEventSequenceStateStart];
    });

    context(@"regardless of predicate", ^{
      beforeEach(^{
        OCMReject([possiblePredicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]);
        OCMReject([activePredicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]);
      });

      it(@"should raise if receives event with LTTouchEventSequenceStateStart", ^{
        expect(^{
          [filter filterContentTouchEvents:LTContentTouchEventMocks(1)
                    withTouchSequenceState:LTTouchEventSequenceStateStart];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should not filter LTTouchEventSequenceStateEnd event regardless of predicates", ^{
        LTContentTouchEvents *events = LTContentTouchEventMocks(1);
        LTContentTouchEvents *filteredEvents =
        [filter filterContentTouchEvents:events
                  withTouchSequenceState:LTTouchEventSequenceStateEnd];
        expect(filteredEvents).to.haveCountOf(1);
        expect(filteredEvents.firstObject).to.beIdenticalTo(events.firstObject);
      });

      it(@"should change state when receiving LTTouchEventSequenceStateEnd event", ^{
        [filter filterContentTouchEvents:LTContentTouchEventMocks(1)
                  withTouchSequenceState:LTTouchEventSequenceStateEnd];
        expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStateIdle);
        expect(filter.sequenceInitialTouchEvent).to.beNil();
        expect(filter.eventsFilter).to.beNil();
      });

      it(@"should raise if receives multiple LTTouchEventSequenceStateEnd events", ^{
        expect(^{
          [filter filterContentTouchEvents:LTContentTouchEventMocks(2)
                    withTouchSequenceState:LTTouchEventSequenceStateStart];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should not filter LTTouchEventSequenceStateEnd event regardless of predicates", ^{
        LTContentTouchEvents *events = LTContentTouchEventMocks(1);
        LTContentTouchEvents *filteredEvents =
            [filter filterContentTouchEvents:events
                      withTouchSequenceState:LTTouchEventSequenceStateCancellation];
        expect(filteredEvents).to.haveCountOf(1);
        expect(filteredEvents.firstObject).to.beIdenticalTo(events.firstObject);
      });

      it(@"should change state when receiving a LTTouchEventSequenceStateCancellation event", ^{
        [filter filterContentTouchEvents:LTContentTouchEventMocks(1)
                  withTouchSequenceState:LTTouchEventSequenceStateCancellation];
        expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStateIdle);
        expect(filter.sequenceInitialTouchEvent).to.beNil();
        expect(filter.eventsFilter).to.beNil();
      });

      it(@"should raise if receives multiple LTTouchEventSequenceStateCancellation events", ^{
        expect(^{
          [filter filterContentTouchEvents:LTContentTouchEventMocks(2)
                    withTouchSequenceState:LTTouchEventSequenceStateStart];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should change state when cancelActiveSequence is called", ^{
        [filter cancelActiveSequence];
        expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStateIdle);
        expect(filter.sequenceInitialTouchEvent).to.beNil();
        expect(filter.eventsFilter).to.beNil();
      });
    });

    it(@"should remain in possible state if predicate rejects all sequence continuation events", ^{
      OCMReject([activePredicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]);
      OCMStub([possiblePredicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]).andReturn(NO);
      [filter filterContentTouchEvents:LTContentTouchEventMocks(3)
                withTouchSequenceState:LTTouchEventSequenceStateContinuation];
      expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStatePossible);

      [filter filterContentTouchEvents:LTContentTouchEventMocks(3)
                withTouchSequenceState:LTTouchEventSequenceStateContinuationStationary];
      expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStatePossible);
    });

    context(@"changing to active state", ^{
      __block LTContentTouchEvents *events;

      beforeEach(^{
        events = LTContentTouchEventMocks(3);
        OCMExpect([possiblePredicate isValidEvent:events[0] givenEvent:firstEvent]).andReturn(NO);
        OCMExpect([possiblePredicate isValidEvent:events[1] givenEvent:firstEvent]).andReturn(NO);
        OCMExpect([possiblePredicate isValidEvent:events[2] givenEvent:firstEvent]).andReturn(YES);
      });

      afterEach(^{
        OCMVerifyAll(possiblePredicate);
      });

      it(@"should change to active state once predicate accepts a continuation event", ^{
        [filter filterContentTouchEvents:events
                  withTouchSequenceState:LTTouchEventSequenceStateContinuation];
        expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStateActive);
      });

      it(@"should change to active state once predicate accepts a stationary continuation event", ^{
        [filter filterContentTouchEvents:events
                  withTouchSequenceState:LTTouchEventSequenceStateContinuationStationary];
        expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStateActive);
      });

      context(@"testing events after the event accepted by the possible predicate", ^{
        beforeEach(^{
          events = [events arrayByAddingObjectsFromArray:LTContentTouchEventMocks(3)];
          OCMReject([activePredicate isValidEvent:events[0] givenEvent:[OCMArg any]]);
          OCMReject([activePredicate isValidEvent:events[1] givenEvent:[OCMArg any]]);
        });

        it(@"should only test the following continuation events using the active predicate", ^{
          OCMExpect([activePredicate isValidEvent:events[2] givenEvent:firstEvent]).andReturn(NO);
          OCMExpect([activePredicate isValidEvent:events[3] givenEvent:firstEvent]).andReturn(YES);
          OCMExpect([activePredicate isValidEvent:events[4] givenEvent:events[3]]).andReturn(NO);
          OCMExpect([activePredicate isValidEvent:events[5] givenEvent:events[3]]).andReturn(YES);

          LTContentTouchEvents *filteredEvents =
              [filter filterContentTouchEvents:events
                        withTouchSequenceState:LTTouchEventSequenceStateContinuation];

          OCMVerifyAll(activePredicate);
          expect(filteredEvents).to.haveCountOf(2);
          expect(filteredEvents.firstObject).to.beIdenticalTo(events[3]);
          expect(filteredEvents.lastObject).to.beIdenticalTo(events[5]);
        });

        it(@"should only test the following stationary events using the active predicate", ^{
          OCMExpect([activePredicate isValidEvent:events[2] givenEvent:firstEvent]).andReturn(NO);
          OCMExpect([activePredicate isValidEvent:events[3] givenEvent:firstEvent]).andReturn(YES);
          OCMExpect([activePredicate isValidEvent:events[4] givenEvent:events[3]]).andReturn(NO);
          OCMExpect([activePredicate isValidEvent:events[5] givenEvent:events[3]]).andReturn(YES);

          LTContentTouchEvents *filteredEvents =
              [filter filterContentTouchEvents:events
                        withTouchSequenceState:LTTouchEventSequenceStateContinuationStationary];

          OCMVerifyAll(activePredicate);
          expect(filteredEvents).to.haveCountOf(2);
          expect(filteredEvents.firstObject).to.beIdenticalTo(events[3]);
          expect(filteredEvents.lastObject).to.beIdenticalTo(events[5]);
        });
      });
    });
  });

  context(@"active state", ^{
    __block id<LTContentTouchEvent> firstEvent;

    beforeEach(^{
      firstEvent = OCMProtocolMock(@protocol(LTContentTouchEvent));
      [filter filterContentTouchEvents:@[firstEvent]
                withTouchSequenceState:LTTouchEventSequenceStateStart];
      expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStatePossible);

      id<LTContentTouchEvent> secondEvent = OCMProtocolMock(@protocol(LTContentTouchEvent));
      OCMExpect([activePredicate isValidEvent:secondEvent givenEvent:firstEvent]).andReturn(NO);
      OCMExpect([possiblePredicate isValidEvent:secondEvent givenEvent:firstEvent]).andReturn(YES);
      [filter filterContentTouchEvents:@[secondEvent]
                withTouchSequenceState:LTTouchEventSequenceStateContinuation];
      expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStateActive);

      OCMVerifyAll(possiblePredicate);
      OCMVerifyAll(activePredicate);

      OCMReject([possiblePredicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]);
    });

    context(@"regardless of predicate", ^{
      beforeEach(^{
        OCMReject([activePredicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]);
      });

      it(@"should raise if receives event with LTTouchEventSequenceStateStart", ^{
        expect(^{
          [filter filterContentTouchEvents:LTContentTouchEventMocks(1)
                    withTouchSequenceState:LTTouchEventSequenceStateStart];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should not filter LTTouchEventSequenceStateEnd event regardless of predicates", ^{
        LTContentTouchEvents *events = LTContentTouchEventMocks(1);
        LTContentTouchEvents *filteredEvents =
            [filter filterContentTouchEvents:events
                      withTouchSequenceState:LTTouchEventSequenceStateEnd];
        expect(filteredEvents).to.haveCountOf(1);
        expect(filteredEvents.firstObject).to.beIdenticalTo(events.firstObject);
      });

      it(@"should change state when receiving LTTouchEventSequenceStateEnd event", ^{
        [filter filterContentTouchEvents:LTContentTouchEventMocks(1)
                  withTouchSequenceState:LTTouchEventSequenceStateEnd];
        expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStateIdle);
        expect(filter.sequenceInitialTouchEvent).to.beNil();
        expect(filter.eventsFilter).to.beNil();
      });

      it(@"should raise if receives multiple LTTouchEventSequenceStateEnd events", ^{
        expect(^{
          [filter filterContentTouchEvents:LTContentTouchEventMocks(2)
                    withTouchSequenceState:LTTouchEventSequenceStateStart];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should not filter LTTouchEventSequenceStateEnd event regardless of predicates", ^{
        LTContentTouchEvents *events = LTContentTouchEventMocks(1);
        LTContentTouchEvents *filteredEvents =
        [filter filterContentTouchEvents:events
                  withTouchSequenceState:LTTouchEventSequenceStateCancellation];
        expect(filteredEvents).to.haveCountOf(1);
        expect(filteredEvents.firstObject).to.beIdenticalTo(events.firstObject);
      });

      it(@"should change state when receiving a LTTouchEventSequenceStateCancellation event", ^{
        [filter filterContentTouchEvents:LTContentTouchEventMocks(1)
                  withTouchSequenceState:LTTouchEventSequenceStateCancellation];
        expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStateIdle);
        expect(filter.sequenceInitialTouchEvent).to.beNil();
        expect(filter.eventsFilter).to.beNil();
      });

      it(@"should raise if receives multiple LTTouchEventSequenceStateCancellation events", ^{
        expect(^{
          [filter filterContentTouchEvents:LTContentTouchEventMocks(2)
                    withTouchSequenceState:LTTouchEventSequenceStateStart];
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should change state when cancelActiveSequence is called", ^{
        [filter cancelActiveSequence];
        expect(filter.filterState).to.equal(LTContentTouchEventStateFilterStateIdle);
        expect(filter.sequenceInitialTouchEvent).to.beNil();
        expect(filter.eventsFilter).to.beNil();
      });
    });

    context(@"correct filtering of continuation events", ^{
      __block LTContentTouchEvents *events;

      beforeEach(^{
        events = LTContentTouchEventMocks(6);
        OCMExpect([activePredicate isValidEvent:events[0] givenEvent:firstEvent]).andReturn(NO);
        OCMExpect([activePredicate isValidEvent:events[1] givenEvent:firstEvent]).andReturn(NO);
        OCMExpect([activePredicate isValidEvent:events[2] givenEvent:firstEvent]).andReturn(YES);
        OCMExpect([activePredicate isValidEvent:events[3] givenEvent:events[2]]).andReturn(NO);
        OCMExpect([activePredicate isValidEvent:events[4] givenEvent:events[2]]).andReturn(YES);
        OCMExpect([activePredicate isValidEvent:events[5] givenEvent:events[4]]).andReturn(YES);
      });

      afterEach(^{
        OCMVerifyAll(activePredicate);
      });

      it(@"should correctly filter incoming continuation events", ^{
        LTContentTouchEvents *filteredEvents =
            [filter filterContentTouchEvents:events
                      withTouchSequenceState:LTTouchEventSequenceStateContinuation];
        expect(filteredEvents).to.equal(@[events[2], events[4], events[5]]);
      });

      it(@"should correctly filter incoming stationary continuation events", ^{
        LTContentTouchEvents *filteredEvents =
            [filter filterContentTouchEvents:events
                      withTouchSequenceState:LTTouchEventSequenceStateContinuationStationary];
        expect(filteredEvents).to.equal(@[events[2], events[4], events[5]]);
      });

      it(@"should correctly filter incoming continuation events of both types", ^{
        LTContentTouchEvents *filteredEvents;

        filteredEvents = [filter
                          filterContentTouchEvents:@[events[0], events[1]]
                          withTouchSequenceState:LTTouchEventSequenceStateContinuation];
        expect(filteredEvents).to.beEmpty();

        filteredEvents = [filter
                          filterContentTouchEvents:@[events[2], events[3]]
                          withTouchSequenceState:LTTouchEventSequenceStateContinuationStationary];
        expect(filteredEvents).to.haveCountOf(1);
        expect(filteredEvents.firstObject).to.beIdenticalTo(events[2]);

        filteredEvents = [filter
                          filterContentTouchEvents:@[events[4], events[5]]
                          withTouchSequenceState:LTTouchEventSequenceStateContinuation];
        expect(filteredEvents).to.haveCountOf(2);
        expect(filteredEvents.firstObject).to.beIdenticalTo(events[4]);
        expect(filteredEvents.lastObject).to.beIdenticalTo(events[5]);
      });
    });
  });
});

SpecEnd
