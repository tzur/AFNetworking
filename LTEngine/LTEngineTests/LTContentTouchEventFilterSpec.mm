// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventFilter.h"

#import "LTContentTouchEvent.h"
#import "LTContentTouchEventPredicate.h"

static LTContentTouchEvents *LTContentTouchEventMocks(NSUInteger count) {
  LTMutableContentTouchEvents *events = [NSMutableArray array];
  for (NSUInteger i = 0; i < count; ++i) {
    [events addObject:OCMProtocolMock(@protocol(LTContentTouchEvent))];
  }
  return [events copy];
}

SpecBegin(LTContentTouchEventFilter)

__block id<LTContentTouchEventPredicate> predicate;

beforeEach(^{
  predicate = OCMProtocolMock(@protocol(LTContentTouchEventPredicate));
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"hello"];

    LTContentTouchEventFilter *filter =
        [[LTContentTouchEventFilter alloc] initWithPredicate:predicate];

    expect(filter.predicate).to.beIdenticalTo(predicate);
  });
});

context(@"filtering", ^{
  __block LTContentTouchEventFilter *filter;

  beforeEach(^{
    filter = [[LTContentTouchEventFilter alloc] initWithPredicate:predicate];
  });

  context(@"before any event was accepted", ^{
    it(@"should return empty array when empty array is given", ^{
      expect([filter pushEventsAndFilter:@[]]).to.beEmpty();
    });

    it(@"should return the first event if filter rejects all events", ^{
      OCMStub([predicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]).andReturn(NO);
      LTContentTouchEvents *events = LTContentTouchEventMocks(3);
      expect([filter pushEventsAndFilter:events]).to.equal(@[events[0]]);
    });

    it(@"should have the first event as last valid event if filter rejects all events", ^{
      OCMStub([predicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]).andReturn(NO);
      LTContentTouchEvents *events = LTContentTouchEventMocks(3);
      [filter pushEventsAndFilter:events];
      expect(filter.lastValidEvent).to.beIdenticalTo(events[0]);
    });

    it(@"should correctly filter a sequence of events", ^{
      LTContentTouchEvents *events = LTContentTouchEventMocks(6);

      OCMStub([predicate isValidEvent:events[2] givenEvent:events[0]]).andReturn(YES);
      OCMStub([predicate isValidEvent:events[4] givenEvent:events[2]]).andReturn(YES);
      OCMStub([predicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]).andReturn(NO);

      LTContentTouchEvents *filteredEvents = [filter pushEventsAndFilter:events];
      expect(filteredEvents).to.haveCountOf(3);
      expect(filteredEvents[0]).to.beIdenticalTo(events[0]);
      expect(filteredEvents[1]).to.beIdenticalTo(events[2]);
      expect(filteredEvents[2]).to.beIdenticalTo(events[4]);
    });

    it(@"should provide correct last valid event", ^{
      LTContentTouchEvents *events = LTContentTouchEventMocks(6);

      OCMStub([predicate isValidEvent:events[2] givenEvent:events[0]]).andReturn(YES);
      OCMStub([predicate isValidEvent:events[4] givenEvent:events[2]]).andReturn(YES);
      OCMStub([predicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]).andReturn(NO);
      [filter pushEventsAndFilter:events];

      expect(filter.lastValidEvent).to.beIdenticalTo(events[4]);
    });
  });

  context(@"after an event was accepted", ^{
    __block id<LTContentTouchEvent> firstEvent;

    beforeEach(^{
      firstEvent = OCMProtocolMock(@protocol(LTContentTouchEvent));
      [filter pushEventsAndFilter:@[firstEvent]];
    });

    it(@"should return empty array when empty array is given", ^{
      expect([filter pushEventsAndFilter:@[]]).to.beEmpty();
    });

    it(@"should return empty array if filter rejects all events", ^{
      OCMStub([predicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]).andReturn(NO);
      LTContentTouchEvents *events = LTContentTouchEventMocks(3);
      expect([filter pushEventsAndFilter:events]).to.beEmpty();
    });

    it(@"should leave last valid event unchanged if filter rejects all events", ^{
      OCMStub([predicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]).andReturn(NO);
      LTContentTouchEvents *events = LTContentTouchEventMocks(3);
      [filter pushEventsAndFilter:events];
      expect(filter.lastValidEvent).to.beIdenticalTo(firstEvent);
    });

    it(@"should correctly filter a sequence of events", ^{
      LTContentTouchEvents *events = LTContentTouchEventMocks(6);

      OCMStub([predicate isValidEvent:events[1] givenEvent:firstEvent]).andReturn(YES);
      OCMStub([predicate isValidEvent:events[3] givenEvent:events[1]]).andReturn(YES);
      OCMStub([predicate isValidEvent:events[5] givenEvent:events[3]]).andReturn(YES);
      OCMStub([predicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]).andReturn(NO);

      LTContentTouchEvents *filteredEvents = [filter pushEventsAndFilter:events];
      expect(filteredEvents).to.haveCountOf(3);
      expect(filteredEvents[0]).to.beIdenticalTo(events[1]);
      expect(filteredEvents[1]).to.beIdenticalTo(events[3]);
      expect(filteredEvents[2]).to.beIdenticalTo(events[5]);
    });

    it(@"should provide correct last valid event", ^{
      LTContentTouchEvents *events = LTContentTouchEventMocks(6);

      OCMStub([predicate isValidEvent:events[1] givenEvent:firstEvent]).andReturn(YES);
      OCMStub([predicate isValidEvent:events[3] givenEvent:events[1]]).andReturn(YES);
      OCMStub([predicate isValidEvent:events[5] givenEvent:events[3]]).andReturn(YES);
      OCMStub([predicate isValidEvent:[OCMArg any] givenEvent:[OCMArg any]]).andReturn(NO);
      [filter pushEventsAndFilter:events];

      expect(filter.lastValidEvent).to.beIdenticalTo(events[5]);
    });
  });
});

SpecEnd
