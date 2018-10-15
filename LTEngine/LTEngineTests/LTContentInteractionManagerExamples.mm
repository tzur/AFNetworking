// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentInteractionManagerExamples.h"

#import <LTKit/NSArray+NSSet.h>
#import <LTKit/NSSet+Operations.h>

#import "LTContentInteraction.h"
#import "LTContentTouchEvent.h"
#import "LTContentTouchEventDelegate.h"

NSString * const kLTContentInteractionManagerExamples = @"LTContentInteractionManagerExamples";
NSString * const kLTContentInteractionManager = @"LTContentInteractionManager";
NSString * const kLTContentInteractionManagerView = @"LTContentInteractionManagerView";

@interface LTContentInteractionManagerObserver : NSObject
@property (strong, nonatomic) NSArray<UIGestureRecognizer *> *customGestureRecognizers;
@end

@implementation LTContentInteractionManagerObserver

- (void)observeValueForKeyPath:(NSString __unused *)keyPath ofObject:(__unused id)object
                        change:(NSDictionary<NSString *, id> *)change
                       context:(void __unused *)context {
  self.customGestureRecognizers = change[@"new"];
}

@end

SharedExamplesBegin(LTContentInteractionManager)

sharedExamplesFor(kLTContentInteractionManagerExamples, ^(NSDictionary *data) {
  __block NSObject<LTContentInteractionManager, LTContentTouchEventDelegate> *manager;
  __block UIView *view;

  beforeEach(^{
    manager = data[kLTContentInteractionManager];
    view = data[kLTContentInteractionManagerView];
  });

  afterEach(^{
    view = nil;
    manager = nil;
  });

  context(@"setting custom gesture recognizers", ^{
    context(@"attaching custom gesture recognizers", ^{
      __block UITapGestureRecognizer *recognizer;
      __block NSSet<UIGestureRecognizer *> *initialGestureRecognizers;

      beforeEach(^{
        recognizer = [[UITapGestureRecognizer alloc] init];
        initialGestureRecognizers = [NSSet setWithArray:view.gestureRecognizers];
      });

      afterEach(^{
        recognizer = nil;
        view.gestureRecognizers = [initialGestureRecognizers allObjects];
      });

      it(@"should attach new custom gesture recognizers to view", ^{
        manager.customGestureRecognizers = @[recognizer];

        auto gestureRecognizers = [[view.gestureRecognizers lt_set]
                                   lt_minus:initialGestureRecognizers];
        expect(gestureRecognizers).to.haveACountOf(1);
        expect([gestureRecognizers anyObject]).to.beIdenticalTo(recognizer);
      });

      it(@"should detach old custom gesture recognizers from view", ^{
        manager.customGestureRecognizers = @[recognizer];

        manager.customGestureRecognizers = nil;

        NSSet<UIGestureRecognizer *> *gestureRecognizers =
            [NSSet setWithArray:view.gestureRecognizers];
        expect(gestureRecognizers).to.equal(initialGestureRecognizers);
      });

      it(@"should replace custom gesture recognizers", ^{
        manager.customGestureRecognizers = @[recognizer];
        UIPinchGestureRecognizer *anotherRecognizer = [[UIPinchGestureRecognizer alloc] init];

        manager.customGestureRecognizers = @[anotherRecognizer];

        auto gestureRecognizers = [[view.gestureRecognizers lt_set]
                                   lt_minus:initialGestureRecognizers];
        expect(gestureRecognizers).to.haveACountOf(1);
        expect([gestureRecognizers anyObject]).to.beIdenticalTo(anotherRecognizer);
      });
    });
  });

  context(@"KVO compliance", ^{
    __block LTContentInteractionManagerObserver *observer;
    __block NSString *keypath;

    beforeEach(^{
      observer = [[LTContentInteractionManagerObserver alloc] init];
      keypath = @keypath(manager, customGestureRecognizers);
      [manager addObserver:observer forKeyPath:keypath options:NSKeyValueObservingOptionNew
                   context:NULL];
    });

    afterEach(^{
      [manager removeObserver:observer forKeyPath:keypath];
    });

    it(@"should send KVO notification when custom gesture recognizers are modified", ^{
      expect(observer.customGestureRecognizers).to.beNil();
      manager.customGestureRecognizers = @[[[UITapGestureRecognizer alloc] init]];
      expect(observer.customGestureRecognizers).to.equal(manager.customGestureRecognizers);
      manager.customGestureRecognizers = @[];
      expect(observer.customGestureRecognizers).to.equal(manager.customGestureRecognizers);
    });
  });

  context(@"touch event forwarding", ^{
    __block LTContentTouchEvents *contentTouchEvents;
    __block LTContentTouchEvents *predictedContentTouchEvents;
    __block id contentTouchEventDelegateMock;

    beforeEach(^{
      contentTouchEvents = @[];
      predictedContentTouchEvents = @[];
      contentTouchEventDelegateMock = OCMProtocolMock(@protocol(LTContentTouchEventDelegate));
      manager.contentTouchEventDelegate = contentTouchEventDelegateMock;
    });

    afterEach(^{
      contentTouchEventDelegateMock = nil;
      predictedContentTouchEvents = nil;
      contentTouchEvents = nil;
    });

    it(@"should not forward touch events on default", ^{
      [[[contentTouchEventDelegateMock reject] ignoringNonObjectArgs]
       receivedContentTouchEvents:[OCMArg any] predictedEvents:[OCMArg any]
       touchEventSequenceState:LTTouchEventSequenceStateStart];

      [manager receivedContentTouchEvents:contentTouchEvents
                          predictedEvents:predictedContentTouchEvents
                  touchEventSequenceState:LTTouchEventSequenceStateStart];

      OCMVerifyAll(contentTouchEventDelegateMock);
    });

    it(@"should forward touch events if required", ^{
      OCMExpect([contentTouchEventDelegateMock
                 receivedContentTouchEvents:contentTouchEvents
                 predictedEvents:predictedContentTouchEvents
                 touchEventSequenceState:LTTouchEventSequenceStateStart]);

      manager.interactionMode = LTInteractionModeTouchEvents;
      [manager receivedContentTouchEvents:contentTouchEvents
                          predictedEvents:predictedContentTouchEvents
                  touchEventSequenceState:LTTouchEventSequenceStateStart];

      OCMVerifyAll(contentTouchEventDelegateMock);
    });

    it(@"should not forward touch events if required", ^{
      [[[contentTouchEventDelegateMock reject] ignoringNonObjectArgs]
       receivedContentTouchEvents:[OCMArg any] predictedEvents:[OCMArg any]
       touchEventSequenceState:LTTouchEventSequenceStateStart];

      manager.interactionMode = LTInteractionModeNone;
      [manager receivedContentTouchEvents:contentTouchEvents
                          predictedEvents:predictedContentTouchEvents
                  touchEventSequenceState:LTTouchEventSequenceStateStart];

      OCMVerifyAll(contentTouchEventDelegateMock);
    });

    it(@"should not receive touch events initially", ^{
      expect(manager.isCurrentlyReceivingContentTouchEvents).to.beFalsy();
    });
  });

  context(@"stationary content touch event forwarding", ^{
    it(@"should have a truthy initial value", ^{
      expect(manager.forwardStationaryContentTouchEvents).to.beTruthy();
    });

    it(@"should set content touch event forwarding", ^{
      manager.forwardStationaryContentTouchEvents = NO;
      expect(manager.forwardStationaryContentTouchEvents).to.beFalsy();
    });
  });
});

SharedExamplesEnd
