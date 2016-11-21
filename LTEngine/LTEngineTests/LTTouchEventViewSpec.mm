// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventView.h"

#import <LTKit/NSArray+NSSet.h>

#import "LTTouchEvent.h"
#import "LTTouchEventDelegate.h"
#import "LTTouchEventViewTestUtils.h"

@interface LTTouchEventView ()
- (void)forwardStationaryTouchEvents:(CADisplayLink *)link;
@property (readonly, nonatomic) CADisplayLink *displayLink;
@property (readonly, nonatomic) NSProcessInfo *processInfo;
@end

@interface LTTestTouchEventDelegateCall : NSObject
@property (strong, nonatomic) LTTouchEvents *events;
@property (strong, nonatomic) LTTouchEvents *predictedEvents;
@property (nonatomic) LTTouchEventSequenceState state;
@end

@implementation LTTestTouchEventDelegateCall
@end

@interface LTTestTouchEventDelegate : NSObject <LTTouchEventDelegate>
@property (strong, nonatomic) LTVoidBlock block;
@property (strong, nonatomic) LTVoidBlock blockExecutedUponManualTermination;
@property (strong, nonatomic) NSMutableArray<LTTestTouchEventDelegateCall *> *calls;
@property (strong, nonatomic) NSSet<NSNumber *> *idsOfCancelledSequences;
@property (nonatomic) LTTouchEventSequenceState terminationState;
@property (strong, nonatomic) LTMutableTouchEvents *updatedTouchEvents;
@end

@implementation LTTestTouchEventDelegate

- (instancetype)init {
  if (self = [super init]) {
    self.calls = [NSMutableArray array];
    self.updatedTouchEvents = [NSMutableArray array];
  }
  return self;
}

- (void)receivedTouchEvents:(LTTouchEvents *)events predictedEvents:(LTTouchEvents *)predictedEvents
    touchEventSequenceState:(LTTouchEventSequenceState)state {
  [self storeEvents:events predictedEvents:predictedEvents
              state:state];
  if (self.block) {
    self.block();
  }
}

- (void)receivedUpdatesOfTouchEvents:(LTTouchEvents *)events {
  [self.updatedTouchEvents addObjectsFromArray:events];
}

- (void)touchEventSequencesWithIDs:(NSSet<NSNumber *> *)sequenceIDs
               terminatedWithState:(LTTouchEventSequenceState)state {
  if (self.blockExecutedUponManualTermination) {
    self.blockExecutedUponManualTermination();
  }
  self.idsOfCancelledSequences = sequenceIDs;
  self.terminationState = state;
}

- (void)storeEvents:(LTTouchEvents *)events predictedEvents:(LTTouchEvents *)predictedEvents
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
          case LTTouchEventSequenceStateContinuationStationary:
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
            case LTTouchEventSequenceStateContinuationStationary:
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
            case LTTouchEventSequenceStateContinuationStationary:
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

context(@"cancellation", ^{
  __block LTTestTouchEventDelegate *delegate;
  __block LTTouchEventView *view;
  __block id mainTouch;
  __block id anotherMainTouch;
  __block id eventMock;
  __block NSSet<id<LTTouchEvent>> *allTouches;

  beforeEach(^{
    delegate = [[LTTestTouchEventDelegate alloc] init];
    view = [[LTTouchEventView alloc] initWithFrame:CGRectZero delegate:delegate];
    mainTouch = LTTouchEventViewCreateTouch(0);
    anotherMainTouch = LTTouchEventViewCreateTouch(1);
    eventMock = LTTouchEventViewCreateEvent();
    allTouches = [NSSet setWithArray:@[mainTouch, anotherMainTouch]];
  });

  afterEach(^{
    allTouches = nil;
    eventMock = nil;
    mainTouch = nil;
    anotherMainTouch = nil;
    view = nil;
    delegate = nil;
  });

  it(@"should ignore cancellation requests if no touch event sequences are currently occurring", ^{
    [view cancelTouchEventSequences];
    expect(delegate.idsOfCancelledSequences).to.beNil();
    expect(delegate.terminationState).toNot.equal(LTTouchEventSequenceStateCancellation);
  });

  it(@"should cancel existing touch event sequences", ^{
    [view touchesBegan:allTouches withEvent:eventMock];
    expect(delegate.idsOfCancelledSequences).to.beNil();
    expect(delegate.terminationState).toNot.equal(LTTouchEventSequenceStateCancellation);
    [view cancelTouchEventSequences];
    expect(delegate.idsOfCancelledSequences).to.haveACountOf(2);
    expect(delegate.idsOfCancelledSequences).to.contain(@0);
    expect(delegate.idsOfCancelledSequences).to.contain(@1);
    expect(delegate.terminationState).to.equal(LTTouchEventSequenceStateCancellation);
  });

  it(@"should cancel existing touch event sequences and not report another termination", ^{
    [view touchesBegan:allTouches withEvent:eventMock];
    [view cancelTouchEventSequences];
    [delegate.calls removeAllObjects];
    [view touchesEnded:allTouches withEvent:eventMock];
    expect(delegate.calls).to.haveACountOf(0);
  });

  it(@"should cancel existing touch event sequences and not report another cancellation", ^{
    [view touchesBegan:allTouches withEvent:eventMock];
    [view cancelTouchEventSequences];
    [delegate.calls removeAllObjects];
    [view touchesCancelled:allTouches withEvent:eventMock];
    expect(delegate.calls).to.haveACountOf(0);
  });

  it(@"should cancel inside delegate calls informing about start", ^{
    __block LTVoidBlock block = ^{
      [view cancelTouchEventSequences];
    };

    delegate.block = block;
    [view touchesBegan:allTouches withEvent:eventMock];

    expect(delegate.calls).to.haveACountOf(1);
    expect(delegate.calls.firstObject.events.firstObject.timestamp).to.equal(0);
    expect(delegate.idsOfCancelledSequences).to.haveACountOf(2);
    expect(delegate.terminationState).to.equal(LTTouchEventSequenceStateCancellation);
  });

  it(@"should cancel inside delegate calls informing about a single touch sequence continuing", ^{
    __block LTVoidBlock block = ^{
      [view cancelTouchEventSequences];
    };

    [view touchesBegan:allTouches withEvent:eventMock];
    [delegate.calls removeAllObjects];
    delegate.block = block;
    [view touchesMoved:[NSSet setWithArray:@[mainTouch]] withEvent:eventMock];

    expect(delegate.calls).to.haveACountOf(1);
    expect(delegate.calls.firstObject.events.firstObject.timestamp).to.equal(0);
    expect(delegate.idsOfCancelledSequences).to.haveACountOf(2);
    expect(delegate.idsOfCancelledSequences).to.contain(@0);
    expect(delegate.idsOfCancelledSequences).to.contain(@1);
    expect(delegate.terminationState).to.equal(LTTouchEventSequenceStateCancellation);
  });

  it(@"should cancel inside delegate calls informing about multiple touch sequences continuing", ^{
    __block LTVoidBlock block = ^{
      [view cancelTouchEventSequences];
    };

    [view touchesBegan:allTouches withEvent:eventMock];
    [delegate.calls removeAllObjects];
    delegate.block = block;
    [view touchesMoved:allTouches withEvent:eventMock];

    expect(delegate.calls).to.haveACountOf(1);
    expect(delegate.calls.firstObject.events.firstObject.timestamp).to.equal(0);
    expect(delegate.idsOfCancelledSequences).to.haveACountOf(2);
    expect(delegate.idsOfCancelledSequences).to.contain(@0);
    expect(delegate.idsOfCancelledSequences).to.contain(@1);
    expect(delegate.terminationState).to.equal(LTTouchEventSequenceStateCancellation);
  });

  it(@"should allow cancellation requests inside delegate calls informing about termination", ^{
    __block LTVoidBlock block = ^{
      [view cancelTouchEventSequences];
    };

    [view touchesBegan:allTouches withEvent:eventMock];
    [delegate.calls removeAllObjects];
    delegate.block = block;
    [view touchesEnded:[NSSet setWithArray:@[mainTouch]] withEvent:eventMock];

    expect(delegate.calls).to.haveACountOf(1);
    expect(delegate.calls.firstObject.events.firstObject.timestamp).to.equal(0);
    expect(delegate.idsOfCancelledSequences).to.haveACountOf(1);
    expect(delegate.terminationState).to.equal(LTTouchEventSequenceStateCancellation);
  });

  it(@"should allow cancellation requests inside delegate calls informing about cancellation", ^{
    __block LTVoidBlock block = ^{
      [view cancelTouchEventSequences];
    };

    [view touchesBegan:allTouches withEvent:eventMock];
    [delegate.calls removeAllObjects];
    delegate.block = block;
    [view touchesCancelled:[NSSet setWithArray:@[mainTouch]] withEvent:eventMock];

    expect(delegate.calls).to.haveACountOf(1);
    expect(delegate.calls.firstObject.events.firstObject.timestamp).to.equal(0);
    expect(delegate.idsOfCancelledSequences).to.haveACountOf(1);
    expect(delegate.terminationState).to.equal(LTTouchEventSequenceStateCancellation);
  });

  it(@"should ignore cancellation requests except for the first one", ^{
    [view touchesBegan:allTouches withEvent:eventMock];

    // First cancellation request.
    [view cancelTouchEventSequences];

    expect(delegate.idsOfCancelledSequences).to.haveACountOf(2);
    expect(delegate.idsOfCancelledSequences).to.contain(@0);
    expect(delegate.idsOfCancelledSequences).to.contain(@1);
    expect(delegate.terminationState).to.equal(LTTouchEventSequenceStateCancellation);

    // Second cancellation request.
    delegate.idsOfCancelledSequences = nil;
    delegate.terminationState = LTTouchEventSequenceStateStart;

    [view cancelTouchEventSequences];

    expect(delegate.idsOfCancelledSequences).to.beNil();
    expect(delegate.terminationState).to.equal(LTTouchEventSequenceStateStart);
  });

  it(@"should ignore nested cancellation requests except for the first one", ^{
    [view touchesBegan:allTouches withEvent:eventMock];

    delegate.blockExecutedUponManualTermination = ^{
      [view cancelTouchEventSequences];
    };

    [view cancelTouchEventSequences];

    expect(delegate.idsOfCancelledSequences).to.haveACountOf(2);
    expect(delegate.idsOfCancelledSequences).to.contain(@0);
    expect(delegate.idsOfCancelledSequences).to.contain(@1);
    expect(delegate.terminationState).to.equal(LTTouchEventSequenceStateCancellation);
  });

  it(@"should ignore cancellation requests if termination has already been reported", ^{
    [view touchesBegan:allTouches withEvent:eventMock];
    [delegate.calls removeAllObjects];
    [view touchesEnded:allTouches withEvent:eventMock];
    expect(delegate.calls).to.haveACountOf(2);
    [view cancelTouchEventSequences];
    expect(delegate.idsOfCancelledSequences).to.beNil();
    expect(delegate.terminationState).toNot.equal(LTTouchEventSequenceStateCancellation);
  });

  it(@"should ignore cancellation requests if cancellation has already been reported", ^{
    [view touchesBegan:allTouches withEvent:eventMock];
    [delegate.calls removeAllObjects];
    [view touchesCancelled:allTouches withEvent:eventMock];
    expect(delegate.calls).to.haveACountOf(2);
    [view cancelTouchEventSequences];
    expect(delegate.idsOfCancelledSequences).to.beNil();
    expect(delegate.terminationState).toNot.equal(LTTouchEventSequenceStateCancellation);
  });

  it(@"should ignore cancellation requests if termination has already been performed", ^{
    __block NSUInteger numberOfCall = 0;
    __block LTVoidBlock block = ^{
      numberOfCall++;
      if (numberOfCall == 2) {
        [view cancelTouchEventSequences];
      }
    };

    [view touchesBegan:allTouches withEvent:eventMock];
    [delegate.calls removeAllObjects];
    delegate.block = block;
    [view touchesEnded:allTouches withEvent:eventMock];

    expect(delegate.calls).to.haveACountOf(2);
    expect(delegate.idsOfCancelledSequences).to.beNil();
    expect(delegate.terminationState).toNot.equal(LTTouchEventSequenceStateCancellation);
  });

  it(@"should ignore cancellation requests if cancellation has already been performed", ^{
    __block NSUInteger numberOfCall = 0;
    __block LTVoidBlock block = ^{
      if (numberOfCall == 2) {
        [view cancelTouchEventSequences];
      }
    };

    [view touchesBegan:allTouches withEvent:eventMock];
    [delegate.calls removeAllObjects];
    delegate.block = block;
    [view touchesCancelled:allTouches withEvent:eventMock];

    expect(delegate.calls).to.haveACountOf(2);
    expect(delegate.idsOfCancelledSequences).to.beNil();
    expect(delegate.terminationState).toNot.equal(LTTouchEventSequenceStateCancellation);
  });
});

context(@"forwarding of stationary touch events", ^{
  __block id mainTouch0;
  __block id mainTouch1;
  __block id mainTouch2;
  __block LTTouchEventView *view;
  __block LTTestTouchEventDelegate *delegate;
  __block id processInfoPartialMock;

  beforeEach(^{
    mainTouch0 = LTTouchEventViewCreateTouch(0);
    mainTouch1 = LTTouchEventViewCreateTouch(1);
    mainTouch2 = LTTouchEventViewCreateTouch(2);
    id eventMock = LTTouchEventViewCreateEvent();

    delegate = [[LTTestTouchEventDelegate alloc] init];

    view = [[LTTouchEventView alloc] initWithFrame:CGRectZero delegate:delegate];
    processInfoPartialMock = OCMPartialMock(view.processInfo);
    [view touchesBegan:[NSSet setWithArray:@[mainTouch0, mainTouch1]] withEvent:eventMock];
    [view touchesBegan:[NSSet setWithArray:@[mainTouch2]] withEvent:eventMock];
    [delegate.calls removeAllObjects];
  });

  it(@"should correctly forward stationary touch events, according to CADisplayLink", ^{
    OCMStub([mainTouch0 phase]).andReturn(UITouchPhaseStationary);
    OCMStub([mainTouch1 phase]).andReturn(UITouchPhaseStationary);
    OCMStub([mainTouch2 phase]).andReturn(UITouchPhaseBegan);
    OCMExpect([processInfoPartialMock systemUptime]).andReturn(123.456);

    [view forwardStationaryTouchEvents:OCMClassMock([CADisplayLink class])];

    expect(delegate.calls).to.haveACountOf(2);
    expect(delegate.calls[0].events).to.haveACountOf(1);
    expect(delegate.calls[0].predictedEvents).to.haveACountOf(0);
    expect(delegate.calls[0].state).to.equal(LTTouchEventSequenceStateContinuationStationary);
    expect(delegate.calls[1].events).to.haveACountOf(1);
    expect(delegate.calls[1].predictedEvents).to.haveACountOf(0);
    expect(delegate.calls[1].state).to.equal(LTTouchEventSequenceStateContinuationStationary);

    expect(delegate.calls[0].events[0].timestamp).to.equal(123.456);
    expect(delegate.calls[1].events[0].timestamp).to.equal(123.456);

    id<LTTouchEvent> touchEvent = !delegate.calls[0].events[0].sequenceID ?
        delegate.calls[0].events[0] : delegate.calls[1].events[0];
    id<LTTouchEvent> otherTouchEvent = delegate.calls[0].events[0].sequenceID ?
        delegate.calls[0].events[0] : delegate.calls[1].events[0];

    expect(touchEvent.sequenceID).to.equal(0);
    expect(otherTouchEvent.sequenceID).to.equal(1);
    expect(touchEvent.phase).to.equal(UITouchPhaseStationary);
    expect(otherTouchEvent.phase).to.equal(UITouchPhaseStationary);

    OCMVerifyAll(processInfoPartialMock);
  });
});

context(@"display link", ^{
  __block LTTouchEventView *view;

  beforeEach(^{
    id delegate = OCMProtocolMock(@protocol(LTTouchEventDelegate));
    view = [[LTTouchEventView alloc] initWithFrame:CGRectZero delegate:delegate];
  });

  it(@"should initially set up a paused display link", ^{
    expect(view.displayLink.paused).to.beTruthy();
  });

  context(@"updates of display link", ^{
    __block NSSet<UITouch *> *touchMocks;
    __block id eventMock;

    beforeEach(^{
      touchMocks = [NSSet setWithArray:@[LTTouchEventViewCreateTouch(0)]];
      eventMock = LTTouchEventViewCreateEvent();
    });

    it(@"should unpause display link when there are active touches", ^{
      [view touchesBegan:touchMocks withEvent:eventMock];
      expect(view.displayLink.paused).to.beFalsy();
    });

    it(@"should pause display link when there are no active touches", ^{
      [view touchesBegan:touchMocks withEvent:eventMock];
      [view touchesEnded:touchMocks withEvent:eventMock];
      expect(view.displayLink.paused).to.beTruthy();
    });
  });
});

it(@"should gracefully handle nil values for coalesced touch events by returning the main touch", ^{
  LTTestTouchEventDelegate *delegate = [[LTTestTouchEventDelegate alloc] init];
  LTTouchEventView *view = [[LTTouchEventView alloc] initWithFrame:CGRectZero delegate:delegate];
  id touchMock = LTTouchEventViewCreateTouch(7);
  NSSet<UITouch *> *touchMocks = [@[touchMock] lt_set];
  id eventMock = OCMClassMock([UIEvent class]);

  OCMExpect([eventMock respondsToSelector:@selector(coalescedTouchesForTouch:)]).andReturn(@YES);
  OCMExpect([eventMock coalescedTouchesForTouch:touchMock]);

  [view touchesBegan:touchMocks withEvent:eventMock];

  expect(delegate.calls).to.haveACountOf(1);
  expect(delegate.calls.firstObject.events).to.haveACountOf(1);
  expect(delegate.calls.firstObject.events.firstObject.timestamp).to.equal(7);
  OCMVerifyAll(eventMock);
});

context(@"estimated properties", ^{
  it(@"should ignore property updates of touches belonging to already terminated sequences", ^{
    id<LTTouchEventDelegate> delegateMock = OCMStrictProtocolMock(@protocol(LTTouchEventDelegate));
    LTTouchEventView *view = [[LTTouchEventView alloc] initWithFrame:CGRectZero
                                                            delegate:delegateMock];
    id touchMock = LTTouchEventViewCreateTouch(7);
    NSSet<UITouch *> *touchMocks = [@[touchMock] lt_set];

    [view touchesEstimatedPropertiesUpdated:touchMocks];
  });

  it(@"should only forward property updates of touches belonging to occurring sequences", ^{
    LTTestTouchEventDelegate *delegate = [[LTTestTouchEventDelegate alloc] init];
    LTTouchEventView *view = [[LTTouchEventView alloc] initWithFrame:CGRectZero delegate:delegate];
    id touchMock = LTTouchEventViewCreateTouch(7);
    id anotherTouchMock = LTTouchEventViewCreateTouch(8);
    NSSet<UITouch *> *touchMocks = [@[touchMock, anotherTouchMock] lt_set];
    id eventMock = OCMClassMock([UIEvent class]);

    [view touchesBegan:touchMocks withEvent:eventMock];

    NSSet<UITouch *> *endedTouchMocks = [@[touchMock] lt_set];

    [view touchesEnded:endedTouchMocks withEvent:eventMock];

    [view touchesEstimatedPropertiesUpdated:touchMocks];

    expect(delegate.updatedTouchEvents).to.haveACountOf(1);
    expect(delegate.updatedTouchEvents.firstObject.timestamp).to.equal(8);
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
