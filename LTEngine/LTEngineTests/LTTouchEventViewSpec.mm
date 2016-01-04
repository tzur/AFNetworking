// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventView.h"

#import "LTTouchEvent.h"
#import "LTTouchEventDelegate.h"
#import "LTTouchEventViewTestUtils.h"

@interface LTTestTouchEventDelegateCall : NSObject
@property (strong, nonatomic) NSArray<LTTouchEvent *> *events;
@property (strong, nonatomic) NSArray<LTTouchEvent *> *predictedEvents;
@property (nonatomic) LTTouchEventSequenceState state;
@end

@implementation LTTestTouchEventDelegateCall
@end

@interface LTTestTouchEventDelegate : NSObject <LTTouchEventDelegate>
@property (strong, nonatomic) NSMutableArray<LTTestTouchEventDelegateCall *> *calls;
@end

@implementation LTTestTouchEventDelegate

- (instancetype)init {
  if (self = [super init]) {
    self.calls = [NSMutableArray array];
  }
  return self;
}

- (void)receivedTouchEvents:(NSArray<LTTouchEvent *> *)events
            predictedEvents:(NSArray<LTTouchEvent *> *)predictedEvents
    touchEventSequenceState:(LTTouchEventSequenceState)state {
  [self storeEvents:events predictedEvents:predictedEvents
              state:state];
}

- (void)receivedUpdatesOfTouchEvents:(NSArray<LTTouchEvent *> __unused *)events {
}

- (void)storeEvents:(NSArray<LTTouchEvent *> *)events
    predictedEvents:(NSArray<LTTouchEvent *> *)predictedEvents
              state:(LTTouchEventSequenceState)state {
  LTTestTouchEventDelegateCall *call = [[LTTestTouchEventDelegateCall alloc] init];
  call.events = events;
  call.predictedEvents = predictedEvents;
  call.state = state;
  [self.calls addObject:call];
}

@end

@interface LTTestUIEvent : UIEvent
@property (nonatomic) BOOL respondsToCoalescedTouchesSelector;
@property (nonatomic) BOOL respondsToPredictedTouchesSelector;
@end

@implementation LTTestUIEvent

- (BOOL)respondsToSelector:(SEL)selector {
  if (selector == @selector(coalescedTouchesForTouch:)) {
    return self.respondsToCoalescedTouchesSelector;
  } else if (selector == @selector(predictedTouchesForTouch:)) {
    return self.respondsToPredictedTouchesSelector;
  }
  return [super respondsToSelector:selector];
}

@end

NSString * const kLTTouchEventViewExamples = @"LTTouchEventViewExamples";
NSString * const kLTTouchEventViewSequenceState = @"LTTouchEventViewSequenceState";

SharedExamplesBegin(LTTouchEventView)

sharedExamplesFor(kLTTouchEventViewExamples, ^(NSDictionary *data) {
  __block id eventMock;
  __block NSSet<UITouch *> *allTouches;
  __block LTTouchEventSequenceState state;

  beforeEach(^{
    state = (LTTouchEventSequenceState)[data[kLTTouchEventViewSequenceState] integerValue];

    id mainTouch0 = LTTouchEventViewCreateTouch(0);
    id mainTouch1 = LTTouchEventViewCreateTouch(1);
    id mainTouch2 = LTTouchEventViewCreateTouch(2);
    eventMock = LTTouchEventViewCreateEvent();

    LTTouchEventViewMakeEventReturnTouchesForTouch(eventMock, mainTouch0,
                                                   LTTouchEventViewCreateTouches({0, 0.5}),
                                                   LTTouchEventViewCreateTouches({1}));
    LTTouchEventViewMakeEventReturnTouchesForTouch(eventMock, mainTouch1,
                                                   LTTouchEventViewCreateTouches({1, 1.25, 1.5}),
                                                   LTTouchEventViewCreateTouches({3, 2.5}));
    LTTouchEventViewMakeEventReturnTouchesForTouch(eventMock, mainTouch2,
                                                   LTTouchEventViewCreateTouches({2.5, 2}),
                                                   LTTouchEventViewCreateTouches({4}));

    allTouches = [NSSet setWithArray:@[mainTouch1, mainTouch2, mainTouch0]];
  });

  context(@"touch handling", ^{
    context(@"beginning touch event sequence", ^{
      __block NSArray<LTTestTouchEventDelegateCall *> *calls;

      beforeEach(^{
        LTTestTouchEventDelegate *delegate = [[LTTestTouchEventDelegate alloc] init];
        LTTouchEventView *view = [[LTTouchEventView alloc] initWithFrame:CGRectZero
                                                                delegate:delegate];
        [delegate.calls removeAllObjects];

        switch (state) {
          case LTTouchEventSequenceStateStart:
            [view touchesBegan:allTouches withEvent:eventMock];
            break;
          case LTTouchEventSequenceStateContinuation:
            [view touchesBegan:allTouches withEvent:eventMock];
            [delegate.calls removeAllObjects];
            [view touchesMoved:allTouches withEvent:eventMock];
            break;
          case LTTouchEventSequenceStateEnd:
            [view touchesBegan:allTouches withEvent:eventMock];
            [delegate.calls removeAllObjects];
            [view touchesEnded:allTouches withEvent:eventMock];
            break;
          case LTTouchEventSequenceStateCancellation:
            [view touchesBegan:allTouches withEvent:eventMock];
            [delegate.calls removeAllObjects];
            [view touchesCancelled:allTouches withEvent:eventMock];
            break;
        }

        calls = [delegate.calls copy];
      });

      it(@"should delegate all converted touches of beginning sequences to its delegate", ^{
        expect(calls.count).to.equal(3);
        expect(calls[0].state).to.equal(state);
        expect(calls[1].state).to.equal(state);
        expect(calls[2].state).to.equal(state);
      });

      context(@"event not responding to coalesced touches selector", ^{
        beforeEach(^{
          LTTestTouchEventDelegate *delegate = [[LTTestTouchEventDelegate alloc] init];
          LTTouchEventView *view = [[LTTouchEventView alloc] initWithFrame:CGRectZero
                                                                  delegate:delegate];
          LTTestUIEvent *event = [[LTTestUIEvent alloc] init];
          event.respondsToCoalescedTouchesSelector = NO;
          [delegate.calls removeAllObjects];

          switch (state) {
            case LTTouchEventSequenceStateStart:
              [view touchesBegan:allTouches withEvent:event];
              break;
            case LTTouchEventSequenceStateContinuation:
              [view touchesBegan:allTouches withEvent:eventMock];
              [delegate.calls removeAllObjects];
              [view touchesMoved:allTouches withEvent:event];
              break;
            case LTTouchEventSequenceStateEnd:
              [view touchesBegan:allTouches withEvent:eventMock];
              [delegate.calls removeAllObjects];
              [view touchesEnded:allTouches withEvent:event];
              break;
            case LTTouchEventSequenceStateCancellation:
              [view touchesBegan:allTouches withEvent:eventMock];
              [delegate.calls removeAllObjects];
              [view touchesCancelled:allTouches withEvent:event];
              break;
          }

          calls = [delegate.calls copy];
        });

        it(@"should convert only main touches", ^{
          expect(calls[0].events.count).to.equal(1);
          expect(calls[1].events.count).to.equal(1);
          expect(calls[2].events.count).to.equal(1);
        });

        it(@"should use different sequence IDs for different main touches", ^{
          NSSet *sequenceIDs =
              [NSSet setWithArray:@[@(calls[0].events.firstObject.sequenceID),
                                    @(calls[1].events.firstObject.sequenceID),
                                    @(calls[2].events.firstObject.sequenceID)]];
          expect(sequenceIDs.count).to.equal(3);
        });

        it(@"should sort the main touches according to their timestamp", ^{
          expect(calls[0].events.firstObject.timestamp).to.equal(0);
          expect(calls[1].events.firstObject.timestamp).to.equal(1);
          expect(calls[2].events.firstObject.timestamp).to.equal(2);
        });
      });

      context(@"event responding to coalesced touches selector", ^{
        it(@"should convert only coalesced touches", ^{
          expect(calls[0].events.count).to.equal(2);
          expect(calls[1].events.count).to.equal(3);
          expect(calls[2].events.count).to.equal(2);
        });

        it(@"should use different sequence IDs for different coalesced touches", ^{
          NSSet *sequenceIDs =
              [NSSet setWithArray:@[@(calls[0].events.firstObject.sequenceID),
                                    @(calls[1].events.firstObject.sequenceID),
                                    @(calls[2].events.firstObject.sequenceID)]];
          expect(sequenceIDs.count).to.equal(3);
        });

        it(@"should use the same sequence ID for coalesced touches of the same main touch", ^{
          for (LTTestTouchEventDelegateCall *call in calls) {
            NSMutableSet *sequenceIDs = [NSMutableSet set];
            for (LTTouchEvent *event in call.events) {
              [sequenceIDs addObject:@(event.sequenceID)];
            }
            expect(sequenceIDs.count).to.equal(1);
          }
        });

        it(@"should sort the coalesced touches according to their timestamp", ^{
          expect(calls[0].events[0].timestamp).to.equal(0);
          expect(calls[0].events[1].timestamp).to.equal(0.5);

          expect(calls[1].events[0].timestamp).to.equal(1);
          expect(calls[1].events[1].timestamp).to.equal(1.25);
          expect(calls[1].events[2].timestamp).to.equal(1.5);

          expect(calls[2].events[0].timestamp).to.equal(2);
          expect(calls[2].events[1].timestamp).to.equal(2.5);
        });
      });

      context(@"event not responding to predicted touches selector", ^{
        beforeEach(^{
          LTTestTouchEventDelegate *delegate = [[LTTestTouchEventDelegate alloc] init];
          LTTouchEventView *view = [[LTTouchEventView alloc] initWithFrame:CGRectZero
                                                                  delegate:delegate];
          LTTestUIEvent *event = [[LTTestUIEvent alloc] init];
          event.respondsToPredictedTouchesSelector = NO;
          [delegate.calls removeAllObjects];

          switch (state) {
            case LTTouchEventSequenceStateStart:
              [view touchesBegan:allTouches withEvent:event];
              break;
            case LTTouchEventSequenceStateContinuation:
              [view touchesBegan:allTouches withEvent:eventMock];
              [delegate.calls removeAllObjects];
              [view touchesMoved:allTouches withEvent:event];
              break;
            case LTTouchEventSequenceStateEnd:
              [view touchesBegan:allTouches withEvent:eventMock];
              [delegate.calls removeAllObjects];
              [view touchesEnded:allTouches withEvent:event];
              break;
            case LTTouchEventSequenceStateCancellation:
              [view touchesBegan:allTouches withEvent:eventMock];
              [delegate.calls removeAllObjects];
              [view touchesCancelled:allTouches withEvent:event];
              break;
          }

          calls = [delegate.calls copy];
        });

        it(@"should return empty arrays for non-existing predicted touches", ^{
          expect(calls[0].predictedEvents).toNot.beNil();
          expect(calls[1].predictedEvents).toNot.beNil();
          expect(calls[2].predictedEvents).toNot.beNil();
          expect(calls[0].predictedEvents).to.beEmpty();
          expect(calls[1].predictedEvents).to.beEmpty();
          expect(calls[2].predictedEvents).to.beEmpty();
        });
      });

      context(@"event responding to predicted touches selector", ^{
        it(@"should convert predicted touches", ^{
          expect(calls[0].predictedEvents.count).to.equal(1);
          expect(calls[1].predictedEvents.count).to.equal(2);
          expect(calls[2].predictedEvents.count).to.equal(1);
        });

        it(@"should use different sequence IDs for different predicted touches", ^{
          NSSet *sequenceIDs =
              [NSSet setWithArray:@[@(calls[0].predictedEvents.firstObject.sequenceID),
                                    @(calls[1].predictedEvents.firstObject.sequenceID),
                                    @(calls[2].predictedEvents.firstObject.sequenceID)]];
          expect(sequenceIDs.count).to.equal(3);
        });

        it(@"should use the same sequence ID for predicted touches of the same main touch", ^{
          for (LTTestTouchEventDelegateCall *call in calls) {
            NSMutableSet *sequenceIDs = [NSMutableSet set];
            for (LTTouchEvent *event in call.predictedEvents) {
              [sequenceIDs addObject:@(event.sequenceID)];
            }
            expect(sequenceIDs.count).to.equal(1);
          }
        });

        it(@"should sort the predicted touches according to their timestamp", ^{
          expect(calls[1].predictedEvents[0].timestamp).to.equal(2.5);
          expect(calls[1].predictedEvents[1].timestamp).to.equal(3);
        });
      });
    });
  });
});

SharedExamplesEnd

SpecBegin(LTTouchEventView)

context(@"initialization", ^{
  __block id delegateMock;

  beforeEach(^{
    delegateMock = OCMProtocolMock(@protocol(LTTouchEventDelegate));
  });

  it(@"should initialize with given frame and delegate", ^{
    CGRect frame = CGRectMake(0, 1, 2, 3);
    LTTouchEventView *view = [[LTTouchEventView alloc] initWithFrame:frame delegate:delegateMock];
    expect(view.frame).to.equal(frame);
    expect(view.delegate).to.beIdenticalTo(delegateMock);
  });
});

itShouldBehaveLike(kLTTouchEventViewExamples,
                   @{kLTTouchEventViewSequenceState: @(LTTouchEventSequenceStateStart)});
itShouldBehaveLike(kLTTouchEventViewExamples,
                   @{kLTTouchEventViewSequenceState: @(LTTouchEventSequenceStateContinuation)});
itShouldBehaveLike(kLTTouchEventViewExamples,
                   @{kLTTouchEventViewSequenceState: @(LTTouchEventSequenceStateEnd)});
itShouldBehaveLike(kLTTouchEventViewExamples,
                   @{kLTTouchEventViewSequenceState: @(LTTouchEventSequenceStateCancellation)});

SpecEnd
