// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "WFFloatView.h"

@interface WFFloatView (ForTesting)

/// Handles floating view pan gesture. The given \c panGestureRecognizer is handled as if it was
/// performed on the floating view. Meant to be used for testing only.
- (void)floatingViewPan:(UIPanGestureRecognizer *)panGestureRecognizer;

@end

API_AVAILABLE(ios(10.0))
SpecBegin(WFFloatView)

if (@available(iOS 10.0, *)) {
  __block WFFloatView *floatView;
  __block id delegate;
  __block UIView *contentView;
  __block CGPoint initialPosition;

  /// Name for the initial anchors shared examples.
  static NSString * const kInitialAnchors = @"WFFloatViewInitialAnchors";

  /// Key for the initial anchor entry in the \c data dictionary of the initial anchors shared
  /// example.
  static NSString * const kInitialAnchorKey = @"InitialAnchor";

  /// Key for the expected x position of the initial anchor in the \c data dictionary of the initial
  /// anchors shared example.
  static NSString * const kInitialAnchorExpectedXCoordinateKey =
      @"InitialAnchorExpectedXCoordinate";

  /// Key for the expected y position of the initial anchor in the \c data dictionary of the initial
  /// anchors shared example.
  static NSString * const kInitialAnchorExpectedYCoordinateKey =
      @"InitialAnchorExpectedYCoordinate";

  /// Distance from an anchor low enough to cause snapping to that anchor if a location based
  /// snapping is taking place.
  static const NSUInteger kShortDistance = 1;

  /// Distance from an anchor high enough to cause snapping to another anchor if a location based
  /// snapping is taking place.
  static const NSUInteger kLongDistance = 1000;

  /// Dragging velocity magnitude that is low enough to cause a location based snapping.
  static const NSUInteger kLowVelocity = 1;

  /// Dragging velocity magnitude that is high enough to cause docking.
  static const NSUInteger kHighVelocity = 5000;

  /// Delay for verifying the delegate was notified that the float view snapped the content. Even
  /// though the tests use <tt> +[UIView performWithoutAnimation:] </tt> the completion block of the
  /// animation is invoked in an asynchronous manner, and thus the delay is needed for verification.
  static const NSTimeInterval kDidSnapDelay = 1;

  beforeEach(^{
    delegate = OCMProtocolMock(@protocol(WFFloatViewDelegate));
    [delegate setExpectationOrderMatters:YES];
    floatView = [[WFFloatView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
    floatView.delegate = delegate;
    LTAddViewToWindow(floatView);
    [floatView layoutIfNeeded];
    contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    initialPosition = CGPointMake(100, 100);
  });

  it(@"should initialize properties with documented values", ^{
    expect(floatView.snapInsets).to.equal(UIEdgeInsetsMake(8, 8, 8, 8));
    expect(floatView.leftAccessoryViewWidth).to.equal(0);
    expect(floatView.leftAccessoryViewWidth).to.equal(0);
  });

  sharedExamplesFor(kInitialAnchors, ^(NSDictionary *data) {
    __block WFFloatViewAnchor *initialAnchor;

    beforeEach(^{
      initialAnchor = (WFFloatViewAnchor *)data[kInitialAnchorKey];
    });

    it(@"should animate to initial anchor after setting content", ^{
      [UIView performWithoutAnimation:^{
        [floatView setContentView:contentView initialPosition:initialPosition
                     snapToAnchor:initialAnchor];
        [floatView layoutIfNeeded];
      }];

      OCMVerify([delegate floatView:floatView willBeginAnimatingTo:initialAnchor]);
    });

    it(@"should be snapped to initial anchor after setting content", ^{
      OCMExpect([delegate floatView:floatView didSnapTo:initialAnchor]);

      [UIView performWithoutAnimation:^{
        [floatView setContentView:contentView initialPosition:initialPosition
                     snapToAnchor:initialAnchor];
        [floatView layoutIfNeeded];
      }];

      OCMVerifyAllWithDelay(delegate, kDidSnapDelay);
    });

    it(@"should position content in coordinates of initial anchor after animation ends", ^{
      auto expectedX = ((NSNumber *)data[kInitialAnchorExpectedXCoordinateKey]).doubleValue;
      auto expectedY = ((NSNumber *)data[kInitialAnchorExpectedYCoordinateKey]).doubleValue;
      [UIView performWithoutAnimation:^{
        [floatView setContentView:contentView initialPosition:initialPosition
                     snapToAnchor:initialAnchor];
        [floatView layoutIfNeeded];
      }];

      expect(floatView.contentView.superview.center.x).to.beCloseTo(expectedX);
      expect(floatView.contentView.superview.center.y).to.beCloseTo(expectedY);
    });
  });

  itShouldBehaveLike(kInitialAnchors, ^{
    return @{
      kInitialAnchorKey: $(WFFloatViewAnchorTopCenter),
      kInitialAnchorExpectedXCoordinateKey: @(250),
      kInitialAnchorExpectedYCoordinateKey: @(58)
    };
  });

  itShouldBehaveLike(kInitialAnchors, ^{
    return @{
      kInitialAnchorKey: $(WFFloatViewAnchorBottomCenter),
      kInitialAnchorExpectedXCoordinateKey: @(250),
      kInitialAnchorExpectedYCoordinateKey: @(442)
    };
  });

  itShouldBehaveLike(kInitialAnchors, ^{
    return @{
      kInitialAnchorKey: $(WFFloatViewAnchorTopLeftDock),
      kInitialAnchorExpectedXCoordinateKey: @(50),
      kInitialAnchorExpectedYCoordinateKey: @(58)
    };
  });

  itShouldBehaveLike(kInitialAnchors, ^{
    return @{
      kInitialAnchorKey: $(WFFloatViewAnchorTopRightDock),
      kInitialAnchorExpectedXCoordinateKey: @(450),
      kInitialAnchorExpectedYCoordinateKey: @(58)
    };
  });

  itShouldBehaveLike(kInitialAnchors, ^{
    return @{
      kInitialAnchorKey: $(WFFloatViewAnchorBottomLeftDock),
      kInitialAnchorExpectedXCoordinateKey: @(50),
      kInitialAnchorExpectedYCoordinateKey: @(442)
    };
  });

  itShouldBehaveLike(kInitialAnchors, ^{
    return @{
      kInitialAnchorKey: $(WFFloatViewAnchorBottomRightDock),
      kInitialAnchorExpectedXCoordinateKey: @(450),
      kInitialAnchorExpectedYCoordinateKey: @(442)
    };
  });

  itShouldBehaveLike(kInitialAnchors, ^{
    return @{
      kInitialAnchorKey: $(WFFloatViewAnchorTopLeft),
      kInitialAnchorExpectedXCoordinateKey: @(58),
      kInitialAnchorExpectedYCoordinateKey: @(58)
    };
  });

  itShouldBehaveLike(kInitialAnchors, ^{
    return @{
      kInitialAnchorKey: $(WFFloatViewAnchorTopRight),
      kInitialAnchorExpectedXCoordinateKey: @(442),
      kInitialAnchorExpectedYCoordinateKey: @(58)
    };
  });

  itShouldBehaveLike(kInitialAnchors, ^{
    return @{
      kInitialAnchorKey: $(WFFloatViewAnchorBottomLeft),
      kInitialAnchorExpectedXCoordinateKey: @(58),
      kInitialAnchorExpectedYCoordinateKey: @(442)
    };
  });

  itShouldBehaveLike(kInitialAnchors, ^{
    return @{
      kInitialAnchorKey: $(WFFloatViewAnchorBottomRight),
      kInitialAnchorExpectedXCoordinateKey: @(442),
      kInitialAnchorExpectedYCoordinateKey: @(442)
    };
  });

  context(@"pan gesture", ^{
    __block id panGesturRecognizerMock;

    beforeEach(^{
      panGesturRecognizerMock = OCMClassMock([UIPanGestureRecognizer class]);
    });

    it(@"should drag after pan gesture begins", ^{
      OCMStub([panGesturRecognizerMock state]).andReturn(UIGestureRecognizerStateBegan);
      auto translation = CGPointMake(kShortDistance, kShortDistance);
      OCMStub([panGesturRecognizerMock translationInView:[OCMArg any]]).andReturn(translation);

      [UIView performWithoutAnimation:^{
        [floatView floatingViewPan:panGesturRecognizerMock];
      }];

      OCMVerify([delegate floatViewWillBeginDragging:floatView]);
    });

    context(@"pan from a non dock anchor", ^{
      beforeEach(^{
        floatView.delegate = nil;
        [UIView performWithoutAnimation:^{
          [floatView setContentView:contentView initialPosition:initialPosition
                       snapToAnchor:$(WFFloatViewAnchorTopLeft)];
          [floatView layoutIfNeeded];
        }];
        floatView.delegate = delegate;
      });

      it(@"should snap back when close to previous anchor and pan velocity is low", ^{
        OCMStub([panGesturRecognizerMock state]).andReturn(UIGestureRecognizerStateEnded);
        auto translation = CGPointMake(0, kShortDistance);
        auto velocity = CGPointMake(0, kLowVelocity);
        OCMStub([panGesturRecognizerMock translationInView:[OCMArg any]]).andReturn(translation);
        OCMStub([panGesturRecognizerMock velocityInView:[OCMArg any]]).andReturn(velocity);
        OCMExpect([delegate floatView:floatView
                 willBeginAnimatingTo:$(WFFloatViewAnchorTopLeft)]);
        OCMExpect([delegate floatView:floatView didSnapTo:$(WFFloatViewAnchorTopLeft)]);

        [UIView performWithoutAnimation:^{
          [floatView floatingViewPan:panGesturRecognizerMock];
        }];

        OCMVerifyAllWithDelay(delegate, kDidSnapDelay);
      });

      it(@"should snap to another non dock anchor when closer to it and pan velocity is low", ^{
        OCMStub([panGesturRecognizerMock state]).andReturn(UIGestureRecognizerStateEnded);
        auto translation = CGPointMake(0, kLongDistance);
        auto velocity = CGPointMake(0, kLowVelocity);
        OCMStub([panGesturRecognizerMock translationInView:[OCMArg any]]).andReturn(translation);
        OCMStub([panGesturRecognizerMock velocityInView:[OCMArg any]]).andReturn(velocity);
        OCMExpect([delegate floatView:floatView
                 willBeginAnimatingTo:$(WFFloatViewAnchorBottomLeft)]);
        OCMExpect([delegate floatView:floatView didSnapTo:$(WFFloatViewAnchorBottomLeft)]);

        [UIView performWithoutAnimation:^{
          [floatView floatingViewPan:panGesturRecognizerMock];
        }];

        OCMVerifyAllWithDelay(delegate, kDidSnapDelay);
      });

      it(@"should snap to non dock anchor when pan velocity is high to its direction", ^{
        OCMStub([panGesturRecognizerMock state]).andReturn(UIGestureRecognizerStateEnded);
        auto translation = CGPointMake(0, kShortDistance);
        auto velocity = CGPointMake(0, kHighVelocity);
        OCMStub([panGesturRecognizerMock translationInView:[OCMArg any]]).andReturn(translation);
        OCMStub([panGesturRecognizerMock velocityInView:[OCMArg any]]).andReturn(velocity);
        OCMExpect([delegate floatView:floatView
                 willBeginAnimatingTo:$(WFFloatViewAnchorBottomLeft)]);
        OCMExpect([delegate floatView:floatView didSnapTo:$(WFFloatViewAnchorBottomLeft)]);

        [UIView performWithoutAnimation:^{
          [floatView floatingViewPan:panGesturRecognizerMock];
        }];

        OCMVerifyAllWithDelay(delegate, kDidSnapDelay);
      });

      it(@"should snap to dock anchor when pan velocity is high to its direction", ^{
        OCMStub([panGesturRecognizerMock state]).andReturn(UIGestureRecognizerStateEnded);
        auto translation = CGPointMake(0, kShortDistance);
        auto velocity = CGPointMake(kHighVelocity, 0);
        OCMStub([panGesturRecognizerMock translationInView:[OCMArg any]]).andReturn(translation);
        OCMStub([panGesturRecognizerMock velocityInView:[OCMArg any]]).andReturn(velocity);
        OCMExpect([delegate floatView:floatView
                 willBeginAnimatingTo:$(WFFloatViewAnchorTopRightDock)]);
        OCMExpect([delegate floatView:floatView didSnapTo:$(WFFloatViewAnchorTopRightDock)]);

        [UIView performWithoutAnimation:^{
          [floatView floatingViewPan:panGesturRecognizerMock];
        }];

        OCMVerifyAllWithDelay(delegate, kDidSnapDelay);
      });
    });

    context(@"pan from a dock anchor", ^{
      beforeEach(^{
        floatView.delegate = nil;
        [UIView performWithoutAnimation:^{
          [floatView setContentView:contentView initialPosition:initialPosition
                       snapToAnchor:$(WFFloatViewAnchorTopRightDock)];
          [floatView layoutIfNeeded];
        }];
        floatView.delegate = delegate;
      });

      it(@"should snap to closest non dock anchor when velocity is low", ^{
        OCMStub([panGesturRecognizerMock state]).andReturn(UIGestureRecognizerStateEnded);
        auto translation = CGPointMake(0, 0);
        auto velocity = CGPointMake(0, kLowVelocity);
        OCMStub([panGesturRecognizerMock translationInView:[OCMArg any]]).andReturn(translation);
        OCMStub([panGesturRecognizerMock velocityInView:[OCMArg any]]).andReturn(velocity);
        OCMExpect([delegate floatView:floatView
                 willBeginAnimatingTo:$(WFFloatViewAnchorTopRight)]);
        OCMExpect([delegate floatView:floatView didSnapTo:$(WFFloatViewAnchorTopRight)]);

        [UIView performWithoutAnimation:^{
          [floatView floatingViewPan:panGesturRecognizerMock];
        }];

        OCMVerifyAllWithDelay(delegate, kDidSnapDelay);
      });

      it(@"should snap to non dock anchor according to velocity direction when it's high", ^{
        OCMStub([panGesturRecognizerMock state]).andReturn(UIGestureRecognizerStateEnded);
        auto translation = CGPointMake(0, 0);
        auto velocity = CGPointMake(0, kHighVelocity);
        OCMStub([panGesturRecognizerMock translationInView:[OCMArg any]]).andReturn(translation);
        OCMStub([panGesturRecognizerMock velocityInView:[OCMArg any]]).andReturn(velocity);
        OCMExpect([delegate floatView:floatView
                 willBeginAnimatingTo:$(WFFloatViewAnchorBottomRight)]);
        OCMExpect([delegate floatView:floatView didSnapTo:$(WFFloatViewAnchorBottomRight)]);

        [UIView performWithoutAnimation:^{
          [floatView floatingViewPan:panGesturRecognizerMock];
        }];

        OCMVerifyAllWithDelay(delegate, kDidSnapDelay);
      });
    });

    context(@"pan large content", ^{
      __block UIView *largeContentView;

      beforeEach(^{
        largeContentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 100)];
      });

      it(@"should animate and snap to closest center anchor in location based snapping", ^{
        floatView.delegate = nil;
        [UIView performWithoutAnimation:^{
          [floatView setContentView:largeContentView initialPosition:initialPosition
                       snapToAnchor:$(WFFloatViewAnchorTopRightDock)];
          [floatView layoutIfNeeded];
        }];
        floatView.delegate = delegate;
        OCMExpect([delegate floatView:floatView
                 willBeginAnimatingTo:$(WFFloatViewAnchorTopCenter)]);
        OCMExpect([delegate floatView:floatView didSnapTo:$(WFFloatViewAnchorTopCenter)]);

        [UIView performWithoutAnimation:^{
          [floatView snapToClosestNonDockAnchor];
          [floatView layoutIfNeeded];
        }];

        OCMVerifyAllWithDelay(delegate, kDidSnapDelay);
      });

      it(@"should animate and snap to center anchor when pan velocity is high to its direction", ^{
        floatView.delegate = nil;
        [UIView performWithoutAnimation:^{
          [floatView setContentView:largeContentView initialPosition:initialPosition
                       snapToAnchor:$(WFFloatViewAnchorTopRightDock)];
          [floatView layoutIfNeeded];
        }];
        floatView.delegate = delegate;
        OCMStub([panGesturRecognizerMock state]).andReturn(UIGestureRecognizerStateEnded);
        auto translation = CGPointMake(0, 0);
        auto velocity = CGPointMake(0, kHighVelocity);
        OCMStub([panGesturRecognizerMock translationInView:[OCMArg any]]).andReturn(translation);
        OCMStub([panGesturRecognizerMock velocityInView:[OCMArg any]]).andReturn(velocity);
        OCMExpect([delegate floatView:floatView
                 willBeginAnimatingTo:$(WFFloatViewAnchorBottomCenter)]);
        OCMExpect([delegate floatView:floatView didSnapTo:$(WFFloatViewAnchorBottomCenter)]);

        [UIView performWithoutAnimation:^{
          [floatView floatingViewPan:panGesturRecognizerMock];
        }];

        OCMVerifyAllWithDelay(delegate, kDidSnapDelay);
      });
    });
  });

  it(@"should animate and snap to closest non dock anchor when undocking", ^{
    floatView.delegate = nil;
    [UIView performWithoutAnimation:^{
      [floatView setContentView:contentView initialPosition:initialPosition
                   snapToAnchor:$(WFFloatViewAnchorTopRightDock)];
      [floatView layoutIfNeeded];
    }];
    floatView.delegate = delegate;
    OCMExpect([delegate floatView:floatView
             willBeginAnimatingTo:$(WFFloatViewAnchorTopRight)]);
    OCMExpect([delegate floatView:floatView didSnapTo:$(WFFloatViewAnchorTopRight)]);

    [UIView performWithoutAnimation:^{
      [floatView snapToClosestNonDockAnchor];
      [floatView layoutIfNeeded];
    }];

    OCMVerifyAllWithDelay(delegate, kDidSnapDelay);
  });
}

SpecEnd
