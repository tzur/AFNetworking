// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentInteractionManager.h"

#import "LTContentInteractionManagerExamples.h"
#import "LTContentTouchEventDelegate.h"
#import "LTTouchEventDelegate.h"
#import "LTTouchEventView.h"

SpecBegin(LTContentInteractionManager)

__block LTInteractionGestureRecognizers *recognizers;
__block id tapRecognizerMock;
__block id panRecognizerMock;
__block id pinchRecognizerMock;
__block LTTouchEventView *view;

beforeEach(^{
  tapRecognizerMock = OCMClassMock([UITapGestureRecognizer class]);
  panRecognizerMock = OCMClassMock([UIPanGestureRecognizer class]);
  pinchRecognizerMock = OCMClassMock([UIPinchGestureRecognizer class]);
  recognizers =
      [[LTInteractionGestureRecognizers alloc] initWithTapRecognizer:tapRecognizerMock
                                                       panRecognizer:panRecognizerMock
                                                     pinchRecognizer:pinchRecognizerMock];
  view = OCMClassMock([LTTouchEventView class]);
});

afterEach(^{
  view = nil;
  recognizers = nil;
  pinchRecognizerMock = nil;
  panRecognizerMock = nil;
  tapRecognizerMock = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    LTContentInteractionManager *manager = [[LTContentInteractionManager alloc] initWithView:view];
    expect(manager.defaultGestureRecognizers).toNot.beNil();
    expect(manager.defaultGestureRecognizers.tapGestureRecognizer).to.beNil();
    expect(manager.defaultGestureRecognizers.panGestureRecognizer).to.beNil();
    expect(manager.defaultGestureRecognizers.pinchGestureRecognizer).to.beNil();

    // LTInteractionModeProvider protocol.
    expect(manager.interactionMode).to.equal(LTInteractionModeAllGestures);

    // LTContentInteractionManager protocol.
    expect(manager.customGestureRecognizers).to.beNil();
    expect(manager.contentTouchEventDelegate).to.beNil();

    expect(view.gestureRecognizers).to.beNil();
  });

  it(@"should raise when attempting to initialize with view with attached gesture recognizers", ^{
    id gestureRecognizerMock = OCMClassMock([UIPanGestureRecognizer class]);
    OCMStub([view gestureRecognizers]).andReturn(@[gestureRecognizerMock]);
    expect(^{
      LTContentInteractionManager __unused *manager =
          [[LTContentInteractionManager alloc] initWithView:view];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"setting default gesture recognizers", ^{
  __block LTContentInteractionManager *manager;

  beforeEach(^{
    view =
        [[LTTouchEventView alloc] initWithFrame:CGRectZero
                                       delegate:OCMProtocolMock(@protocol(LTTouchEventDelegate))];
    manager = [[LTContentInteractionManager alloc] initWithView:view];
  });

  afterEach(^{
    manager = nil;
  });

  context(@"attaching default gesture recognizers", ^{
    __block UITapGestureRecognizer *recognizer;

    beforeEach(^{
      recognizer = [[UITapGestureRecognizer alloc] init];
      recognizers = [[LTInteractionGestureRecognizers alloc] initWithTapRecognizer:recognizer
                                                                     panRecognizer:nil
                                                                   pinchRecognizer:nil];
    });

    afterEach(^{
      recognizer = nil;
      recognizers = nil;
    });

    it(@"should attach new default gesture recognizers to view", ^{
      manager.defaultGestureRecognizers = recognizers;

      expect(view.gestureRecognizers).to.haveACountOf(1);
      expect(view.gestureRecognizers.firstObject).to.beIdenticalTo(recognizer);
    });

    it(@"should detach old default gesture recognizers from view", ^{
      manager.defaultGestureRecognizers = recognizers;

      recognizers = [[LTInteractionGestureRecognizers alloc] initWithTapRecognizer:nil
                                                                     panRecognizer:nil
                                                                   pinchRecognizer:nil];
      manager.defaultGestureRecognizers = recognizers;

      expect(view.gestureRecognizers).to.haveACountOf(0);
    });

    it(@"should replace default gesture recognizers", ^{
      manager.defaultGestureRecognizers = recognizers;

      UIPinchGestureRecognizer *anotherRecognizer = [[UIPinchGestureRecognizer alloc] init];

      recognizers =
          [[LTInteractionGestureRecognizers alloc] initWithTapRecognizer:nil panRecognizer:nil
                                                         pinchRecognizer:anotherRecognizer];
      manager.defaultGestureRecognizers = recognizers;

      expect(view.gestureRecognizers).to.haveACountOf(1);
      expect(view.gestureRecognizers.firstObject).to.beIdenticalTo(anotherRecognizer);
    });
  });

  context(@"recognizer setup according to interaction mode", ^{
    it(@"should setup recognizers according to default interaction mode", ^{
      OCMExpect([tapRecognizerMock setEnabled:YES]);
      OCMExpect([panRecognizerMock setEnabled:YES]);
      OCMExpect([pinchRecognizerMock setEnabled:YES]);

      manager.defaultGestureRecognizers = recognizers;

      OCMVerifyAll(tapRecognizerMock);
      OCMVerifyAll(panRecognizerMock);
      OCMVerifyAll(pinchRecognizerMock);
    });

    it(@"should setup recognizers according to no gesture interaction mode", ^{
      manager.interactionMode = LTInteractionModeNone;

      OCMExpect([tapRecognizerMock setEnabled:NO]);
      OCMExpect([panRecognizerMock setEnabled:NO]);
      OCMExpect([pinchRecognizerMock setEnabled:NO]);

      manager.defaultGestureRecognizers = recognizers;

      OCMVerifyAll(tapRecognizerMock);
      OCMVerifyAll(panRecognizerMock);
      OCMVerifyAll(pinchRecognizerMock);
    });

    it(@"should setup recognizers according to tap interaction mode", ^{
      manager.interactionMode = LTInteractionModeTap;

      OCMExpect([tapRecognizerMock setEnabled:YES]);
      OCMExpect([panRecognizerMock setEnabled:NO]);
      OCMExpect([pinchRecognizerMock setEnabled:NO]);

      manager.defaultGestureRecognizers = recognizers;

      OCMVerifyAll(tapRecognizerMock);
      OCMVerifyAll(panRecognizerMock);
      OCMVerifyAll(pinchRecognizerMock);
    });

    it(@"should setup recognizers according to one touch pan interaction mode", ^{
      manager.interactionMode = LTInteractionModePanOneTouch;

      OCMExpect([tapRecognizerMock setEnabled:NO]);
      OCMExpect([panRecognizerMock setEnabled:YES]);
      OCMExpect([panRecognizerMock setMinimumNumberOfTouches:1]);
      OCMExpect([panRecognizerMock setMaximumNumberOfTouches:1]);
      OCMExpect([pinchRecognizerMock setEnabled:NO]);

      manager.defaultGestureRecognizers = recognizers;

      OCMVerifyAll(tapRecognizerMock);
      OCMVerifyAll(panRecognizerMock);
      OCMVerifyAll(pinchRecognizerMock);
    });

    it(@"should setup recognizers according to two touch pan interaction mode", ^{
      manager.interactionMode = LTInteractionModePanTwoTouches;

      OCMExpect([tapRecognizerMock setEnabled:NO]);
      OCMExpect([panRecognizerMock setEnabled:YES]);
      OCMExpect([panRecognizerMock setMinimumNumberOfTouches:2]);
      OCMExpect([panRecognizerMock setMaximumNumberOfTouches:2]);
      OCMExpect([pinchRecognizerMock setEnabled:NO]);

      manager.defaultGestureRecognizers = recognizers;

      OCMVerifyAll(tapRecognizerMock);
      OCMVerifyAll(panRecognizerMock);
      OCMVerifyAll(pinchRecognizerMock);
    });

    it(@"should setup recognizers according to one or two touch pan interaction mode", ^{
      manager.interactionMode = LTInteractionModePanOneTouch | LTInteractionModePanTwoTouches;

      OCMExpect([tapRecognizerMock setEnabled:NO]);
      OCMExpect([panRecognizerMock setEnabled:YES]);
      OCMExpect([panRecognizerMock setMinimumNumberOfTouches:1]);
      OCMExpect([panRecognizerMock setMaximumNumberOfTouches:2]);
      OCMExpect([pinchRecognizerMock setEnabled:NO]);

      manager.defaultGestureRecognizers = recognizers;

      OCMVerifyAll(tapRecognizerMock);
      OCMVerifyAll(panRecognizerMock);
      OCMVerifyAll(pinchRecognizerMock);
    });

    it(@"should setup recognizers according to pinch interaction mode", ^{
      manager.interactionMode = LTInteractionModePinch;

      OCMExpect([tapRecognizerMock setEnabled:NO]);
      OCMExpect([panRecognizerMock setEnabled:NO]);
      OCMExpect([pinchRecognizerMock setEnabled:YES]);

      manager.defaultGestureRecognizers = recognizers;

      OCMVerifyAll(tapRecognizerMock);
      OCMVerifyAll(panRecognizerMock);
      OCMVerifyAll(pinchRecognizerMock);
    });

    it(@"should enable all recognizers if required", ^{
      manager.interactionMode = LTInteractionModeAllGestures;

      OCMExpect([tapRecognizerMock setEnabled:YES]);
      OCMExpect([panRecognizerMock setEnabled:YES]);
      OCMExpect([pinchRecognizerMock setEnabled:YES]);

      manager.defaultGestureRecognizers = recognizers;

      OCMVerifyAll(tapRecognizerMock);
      OCMVerifyAll(panRecognizerMock);
      OCMVerifyAll(pinchRecognizerMock);
    });
  });
});

context(@"invalid calls", ^{
  __block LTContentInteractionManager *manager;

  beforeEach(^{
    view =
        [[LTTouchEventView alloc] initWithFrame:CGRectZero
                                       delegate:OCMProtocolMock(@protocol(LTTouchEventDelegate))];
    manager = [[LTContentInteractionManager alloc] initWithView:view];
  });

  afterEach(^{
    manager = nil;
  });

  it(@"should raise when attempting to attach default gesture recognizers as custom ones", ^{
    manager.defaultGestureRecognizers = recognizers;
    expect(^{
      manager.customGestureRecognizers = @[recognizers.tapGestureRecognizer];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when attempting to attach custom gesture recognizers as default ones", ^{
    manager.customGestureRecognizers = @[tapRecognizerMock, panRecognizerMock];
    expect(^{
      manager.defaultGestureRecognizers = recognizers;
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"setting interaction mode", ^{
  __block LTContentInteractionManager *manager;

  beforeEach(^{
    manager = [[LTContentInteractionManager alloc] initWithView:view];
    manager.defaultGestureRecognizers = recognizers;
  });

  afterEach(^{
    manager = nil;
  });

  it(@"should setup recognizers according to no gesture interaction mode", ^{
    OCMExpect([tapRecognizerMock setEnabled:NO]);
    OCMExpect([panRecognizerMock setEnabled:NO]);
    OCMExpect([pinchRecognizerMock setEnabled:NO]);

    manager.interactionMode = LTInteractionModeNone;

    OCMVerifyAll(tapRecognizerMock);
    OCMVerifyAll(panRecognizerMock);
    OCMVerifyAll(pinchRecognizerMock);
  });

  it(@"should setup recognizers according to tap interaction mode", ^{
    OCMExpect([tapRecognizerMock setEnabled:YES]);
    OCMExpect([panRecognizerMock setEnabled:NO]);
    OCMExpect([pinchRecognizerMock setEnabled:NO]);

    manager.interactionMode = LTInteractionModeTap;

    OCMVerifyAll(tapRecognizerMock);
    OCMVerifyAll(panRecognizerMock);
    OCMVerifyAll(pinchRecognizerMock);
  });

  it(@"should setup recognizers according to one touch pan interaction mode", ^{
    OCMExpect([tapRecognizerMock setEnabled:NO]);
    OCMExpect([panRecognizerMock setEnabled:YES]);
    OCMExpect([panRecognizerMock setMinimumNumberOfTouches:1]);
    OCMExpect([panRecognizerMock setMaximumNumberOfTouches:1]);
    OCMExpect([pinchRecognizerMock setEnabled:NO]);

    manager.interactionMode = LTInteractionModePanOneTouch;

    OCMVerifyAll(tapRecognizerMock);
    OCMVerifyAll(panRecognizerMock);
    OCMVerifyAll(pinchRecognizerMock);
  });

  it(@"should setup recognizers according to two touch pan interaction mode", ^{
    OCMExpect([tapRecognizerMock setEnabled:NO]);
    OCMExpect([panRecognizerMock setEnabled:YES]);
    OCMExpect([panRecognizerMock setMinimumNumberOfTouches:2]);
    OCMExpect([panRecognizerMock setMaximumNumberOfTouches:2]);
    OCMExpect([pinchRecognizerMock setEnabled:NO]);

    manager.interactionMode = LTInteractionModePanTwoTouches;

    OCMVerifyAll(tapRecognizerMock);
    OCMVerifyAll(panRecognizerMock);
    OCMVerifyAll(pinchRecognizerMock);
  });

  it(@"should setup recognizers according to one or two touch pan interaction mode", ^{
    OCMExpect([tapRecognizerMock setEnabled:NO]);
    OCMExpect([panRecognizerMock setEnabled:YES]);
    OCMExpect([panRecognizerMock setMinimumNumberOfTouches:1]);
    OCMExpect([panRecognizerMock setMaximumNumberOfTouches:2]);
    OCMExpect([pinchRecognizerMock setEnabled:NO]);

    manager.interactionMode = LTInteractionModePanOneTouch | LTInteractionModePanTwoTouches;

    OCMVerifyAll(tapRecognizerMock);
    OCMVerifyAll(panRecognizerMock);
    OCMVerifyAll(pinchRecognizerMock);
  });

  it(@"should setup recognizers according to pinch interaction mode", ^{
    OCMExpect([tapRecognizerMock setEnabled:NO]);
    OCMExpect([panRecognizerMock setEnabled:NO]);
    OCMExpect([pinchRecognizerMock setEnabled:YES]);

    manager.interactionMode = LTInteractionModePinch;

    OCMVerifyAll(tapRecognizerMock);
    OCMVerifyAll(panRecognizerMock);
    OCMVerifyAll(pinchRecognizerMock);
  });

  it(@"should enable all recognizers if required", ^{
    OCMExpect([tapRecognizerMock setEnabled:YES]);
    OCMExpect([panRecognizerMock setEnabled:YES]);
    OCMExpect([pinchRecognizerMock setEnabled:YES]);

    manager.interactionMode = LTInteractionModeAllGestures;

    OCMVerifyAll(tapRecognizerMock);
    OCMVerifyAll(panRecognizerMock);
    OCMVerifyAll(pinchRecognizerMock);
  });

  it(@"should cancel sequences when switching between modes with different touch event handling", ^{
    manager.interactionMode = LTInteractionModeTouchEvents;
    OCMVerify([view cancelTouchEventSequences]);

    manager.interactionMode = LTInteractionModeAllGestures;
    OCMVerify([view cancelTouchEventSequences]);
  });

  it(@"should not cancel sequences when switching between mode with same touch event handling", ^{
    OCMReject([view cancelTouchEventSequences]);
    manager.interactionMode = LTInteractionModePanOneTouch;
    manager.interactionMode = LTInteractionModeAllGestures;
  });
});

context(@"LTContentInteractionManager protocol", ^{
  __block LTContentInteractionManager *manager;

  beforeEach(^{
    manager = [[LTContentInteractionManager alloc] initWithView:view];
  });

  itShouldBehaveLike(kLTContentInteractionManagerExamples, ^{
    LTTouchEventView *view =
        [[LTTouchEventView alloc] initWithFrame:CGRectZero
                                       delegate:OCMProtocolMock(@protocol(LTTouchEventDelegate))];
    manager = [[LTContentInteractionManager alloc] initWithView:view];

    return @{
      kLTContentInteractionManager: manager,
      kLTContentInteractionManagerView: view
    };
  });

  it(@"should cancel touch event sequences when setting the content touch event delegate", ^{
    manager.contentTouchEventDelegate = OCMProtocolMock(@protocol(LTContentTouchEventDelegate));
    OCMVerify([view cancelTouchEventSequences]);
  });

  it(@"should retrieve whether to forward stationary content touch events from touch event view", ^{
    OCMStub([view forwardStationaryTouchEvents]).andReturn(YES);
    expect(manager.forwardStationaryContentTouchEvents).to.beTruthy();
  });

  it(@"should proxy the desired rate to the display link", ^{
    manager.forwardStationaryContentTouchEvents = NO;
    OCMVerify([view setForwardStationaryTouchEvents:NO]);
  });
});

SpecEnd
