// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentInteractionManagerExamples.h"

#import "LTContentInteraction.h"
#import "LTContentTouchEvent.h"
#import "LTContentTouchEventDelegate.h"

NSString * const kLTContentInteractionManagerExamples = @"LTContentInteractionManagerExamples";
NSString * const kLTContentInteractionManager = @"LTContentInteractionManager";
NSString * const kLTContentInteractionManagerView = @"LTContentInteractionManagerView";

SharedExamplesBegin(LTContentInteractionManager)

sharedExamplesFor(kLTContentInteractionManagerExamples, ^(NSDictionary *data) {
  __block id<LTContentInteractionManager, LTContentTouchEventDelegate> manager;
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

        NSMutableSet<UIGestureRecognizer *> *gestureRecognizers =
            [[NSSet setWithArray:view.gestureRecognizers] mutableCopy];
        [gestureRecognizers minusSet:initialGestureRecognizers];
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

        NSMutableSet<UIGestureRecognizer *> *gestureRecognizers =
            [[NSSet setWithArray:view.gestureRecognizers] mutableCopy];
        [gestureRecognizers minusSet:initialGestureRecognizers];
        expect(gestureRecognizers).to.haveACountOf(1);
        expect([gestureRecognizers anyObject]).to.beIdenticalTo(anotherRecognizer);
      });
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
  });
});

SharedExamplesEnd
