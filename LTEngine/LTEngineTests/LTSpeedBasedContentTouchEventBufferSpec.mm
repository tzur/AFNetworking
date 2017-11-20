// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSpeedBasedContentTouchEventBuffer.h"

#import "LTContentTouchEvent.h"

static NSArray<LTContentTouchEvent *> *LTFakeContentTouchEvents(CGPoints viewLocations,
                                                                std::vector<NSTimeInterval> times) {
  NSMutableArray<LTContentTouchEvent *> *events = [NSMutableArray array];

  for (CGPoints::size_type i = 0; i < viewLocations.size(); ++i) {
    LTContentTouchEvent *mock = OCMClassMock([LTContentTouchEvent class]);

    CGPoint viewLocation = viewLocations[i];
    CGPoint previousViewLocation = i > 0 ? viewLocations[i - 1] : CGPointNull;
    NSTimeInterval timestamp = times[i];

    OCMStub([mock viewLocation]).andReturn(viewLocation);
    OCMStub([mock previousViewLocation]).andReturn(previousViewLocation);
    OCMStub([mock timestamp]).andReturn(timestamp);
    if (i > 0) {
      NSTimeInterval previousTimestamp = times[i - 1];
      OCMStub([mock previousTimestamp]).andReturn(@(previousTimestamp));
      NSNumber *speed = @(CGPointDistance(viewLocation, previousViewLocation) /
                          (timestamp - previousTimestamp));
      OCMStub([mock speedInViewCoordinates]).andReturn(speed);
    } else {
      OCMStub([mock previousTimestamp]);
      OCMStub([mock speedInViewCoordinates]);
    }
    OCMStub([mock copy]).andReturn(mock);
    [events addObject:mock];
  }

  return events;
}

SpecBegin(LTSpeedBasedContentTouchEventBuffer)

__block LTSpeedBasedContentTouchEventBuffer *buffer;

beforeEach(^{
  buffer = [[LTSpeedBasedContentTouchEventBuffer alloc] init];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(buffer.bufferedEvents).to.equal(@[]);
    expect(buffer.maxSpeed).to.equal(5000);
    expect(buffer.timeIntervals == lt::Interval<NSTimeInterval>({1.0 / 120, 1.0 / 20}))
        .to.beTruthy();
  });
});

context(@"buffering", ^{
  it(@"should not buffer first content touch event", ^{
    NSArray<LTContentTouchEvent *> *events = LTFakeContentTouchEvents({CGPointZero}, {7});
    expect([buffer processAndPossiblyBufferContentTouchEvents:events returnAllEvents:NO])
        .to.equal(events);
    expect(buffer.bufferedEvents).to.equal(@[]);
  });

  it(@"should not buffer first content touch event even if subsequent events are buffered", ^{
    NSArray<LTContentTouchEvent *> *events =
        LTFakeContentTouchEvents({CGPointZero, CGPointMake(0, 1), CGPointMake(0, 2)},
                                 {7, 7.001, 7.002});
    expect([buffer processAndPossiblyBufferContentTouchEvents:events returnAllEvents:NO])
        .to.equal(@[events[0]]);
    expect(buffer.bufferedEvents).to.equal(@[events[1], events[2]]);
  });

  it(@"should buffer content touch events fulfilling condition", ^{
    NSArray<LTContentTouchEvent *> *events =
        LTFakeContentTouchEvents({CGPointZero, CGPointMake(0, 1), CGPointMake(0, 2),
                                  CGPointMake(0, 3)},
                                 {7, 7.01, 7.0101, 7.0102});
    expect([buffer processAndPossiblyBufferContentTouchEvents:events returnAllEvents:NO])
        .to.equal(@[events[0], events[1]]);
    expect(buffer.bufferedEvents).to.equal(@[events[2], events[3]]);
  });

  it(@"should maintain buffered content touch events after processing empty array", ^{
    NSArray<LTContentTouchEvent *> *events =
        LTFakeContentTouchEvents({CGPointZero, CGPointMake(0, 1), CGPointMake(0, 2),
                                  CGPointMake(0, 3)},
                                 {7, 7.01, 7.0101, 7.0102});
    [buffer processAndPossiblyBufferContentTouchEvents:events returnAllEvents:NO];
    expect(buffer.bufferedEvents).to.equal(@[events[2], events[3]]);
    [buffer processAndPossiblyBufferContentTouchEvents:@[] returnAllEvents:NO];
    expect(buffer.bufferedEvents).to.equal(@[events[2], events[3]]);
  });

  it(@"should not buffer any events if returnAllEvents flag is YES", ^{
    NSArray<LTContentTouchEvent *> *events =
        LTFakeContentTouchEvents({CGPointZero, CGPointMake(0, 1), CGPointMake(0, 2),
                                  CGPointMake(0, 3)},
                                 {7, 7.01, 7.0101, 7.0102});
    expect([buffer processAndPossiblyBufferContentTouchEvents:events returnAllEvents:YES])
        .to.equal(events);
    expect(buffer.bufferedEvents).to.equal(@[]);
  });

  context(@"iterative calls", ^{
    it(@"should not buffer first content touch event even if subsequent events are buffered", ^{
      NSArray<LTContentTouchEvent *> *events =
        LTFakeContentTouchEvents({CGPointZero, CGPointMake(0, 1), CGPointMake(0, 2),
                                  CGPointMake(0, 3), CGPointMake(0, 4)},
                                 {7, 7.001, 7.002, 7.003, 7.004});
      NSArray<LTContentTouchEvent *> *subEvents = [events subarrayWithRange:NSMakeRange(0, 3)];
      expect([buffer processAndPossiblyBufferContentTouchEvents:subEvents returnAllEvents:NO])
          .to.equal(@[events[0]]);
      expect(buffer.bufferedEvents).to.equal(@[events[1], events[2]]);

      subEvents = [events subarrayWithRange:NSMakeRange(3, 2)];
      expect([buffer processAndPossiblyBufferContentTouchEvents:subEvents returnAllEvents:NO])
          .to.equal(@[]);
      expect(buffer.bufferedEvents).to.equal(@[events[1], events[2], events[3], events[4]]);
    });

    it(@"should buffer content touch events fulfilling condition", ^{
      NSArray<LTContentTouchEvent *> *events =
        LTFakeContentTouchEvents({CGPointZero, CGPointMake(0, 1), CGPointMake(0, 2),
                                  CGPointMake(0, 3), CGPointMake(0, 3), CGPointMake(0, 5)},
                                 {7, 7.01, 7.0101, 7.0102, 7.1, 7.1001});

      NSArray<LTContentTouchEvent *> *subEvents = [events subarrayWithRange:NSMakeRange(0, 4)];
      expect([buffer processAndPossiblyBufferContentTouchEvents:subEvents returnAllEvents:NO])
          .to.equal(@[events[0], events[1]]);
      expect(buffer.bufferedEvents).to.equal(@[events[2], events[3]]);

      subEvents = [events subarrayWithRange:NSMakeRange(4, 2)];
      expect([buffer processAndPossiblyBufferContentTouchEvents:subEvents returnAllEvents:NO])
          .to.equal(@[events[2], events[3], events[4], events[5]]);
      expect(buffer.bufferedEvents).to.equal(@[]);
    });

    it(@"should not buffer any events if returnAllEvents flag is YES", ^{
      NSArray<LTContentTouchEvent *> *events =
          LTFakeContentTouchEvents({CGPointZero, CGPointMake(0, 1), CGPointMake(0, 2),
                                    CGPointMake(0, 3)},
                                   {7, 7.01, 7.0101, 7.0102});
      expect([buffer processAndPossiblyBufferContentTouchEvents:events returnAllEvents:YES])
          .to.equal(events);
      expect(buffer.bufferedEvents).to.equal(@[]);

      NSArray<LTContentTouchEvent *> *additionalEvents =
          LTFakeContentTouchEvents({CGPointMake(0, 4), CGPointMake(0, 5)},
                                   {7.1, 7.1001});
      expect([buffer processAndPossiblyBufferContentTouchEvents:additionalEvents
                                                returnAllEvents:YES])
          .to.equal(additionalEvents);
      expect(buffer.bufferedEvents).to.equal(@[]);
    });
  });
});

context(@"invalid property values", ^{
  it(@"should raise when attempting to provide with negative maximum speed", ^{
    expect(^{
      buffer.maxSpeed = -1;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when attempting to provide with zero maximum speed", ^{
    expect(^{
      buffer.maxSpeed = 0;
    }).to.raise(NSInvalidArgumentException);
  });
});

SpecEnd
