// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentInteractionManager.h"

#import "LTContentTouchEventDelegate.h"

SpecBegin(LTContentInteractionManager)

__block LTInteractionGestureRecognizers *recognizers;
__block id tapRecognizerMock;
__block id panRecognizerMock;
__block id pinchRecognizerMock;
__block UIView *view;

beforeEach(^{
  tapRecognizerMock = OCMClassMock([UITapGestureRecognizer class]);
  panRecognizerMock = OCMClassMock([UIPanGestureRecognizer class]);
  pinchRecognizerMock = OCMClassMock([UIPinchGestureRecognizer class]);
  recognizers =
      [[LTInteractionGestureRecognizers alloc] initWithTapRecognizer:tapRecognizerMock
                                                       panRecognizer:panRecognizerMock
                                                     pinchRecognizer:pinchRecognizerMock];
  view = [[UIView alloc] initWithFrame:CGRectZero];
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
    expect(manager.touchEventCanceller).to.beNil();
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
    [view addGestureRecognizer:gestureRecognizerMock];
    expect(^{
      LTContentInteractionManager __unused *manager =
          [[LTContentInteractionManager alloc] initWithView:view];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"setting default gesture recognizers", ^{
  __block LTContentInteractionManager *manager;

  beforeEach(^{
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

    it(@"should setup recognizers according to pan interaction mode", ^{
      manager.interactionMode = LTInteractionModePan;

      OCMExpect([tapRecognizerMock setEnabled:NO]);
      OCMExpect([panRecognizerMock setEnabled:YES]);
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
    manager = [[LTContentInteractionManager alloc] initWithView:view];
  });

  afterEach(^{
    manager = nil;
  });

  it(@"it should raise when attempting to attach default gesture recognizers as custom ones", ^{
    manager.defaultGestureRecognizers = recognizers;
    expect(^{
      manager.customGestureRecognizers = @[recognizers.tapGestureRecognizer];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"it should raise when attempting to attach custom gesture recognizers as default ones", ^{
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

  it(@"should setup recognizers according to pan interaction mode", ^{
    OCMExpect([tapRecognizerMock setEnabled:NO]);
    OCMExpect([panRecognizerMock setEnabled:YES]);
    OCMExpect([pinchRecognizerMock setEnabled:NO]);

    manager.interactionMode = LTInteractionModePan;

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
});

context(@"LTContentInteractionManager protocol", ^{
  static UIView * const kView = [[UIView alloc] initWithFrame:CGRectZero];
  static LTContentInteractionManager * const kManager =
      [[LTContentInteractionManager alloc] initWithView:kView];

  itShouldBehaveLike(kLTContentInteractionManagerExamples, @{
      kLTContentInteractionManager: kManager,
      kLTContentInteractionManagerView: kView
  });
});

SpecEnd
