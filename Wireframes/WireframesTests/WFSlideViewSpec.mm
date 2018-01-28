// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "WFSlideView.h"

#import "CALayer+Enumeration.h"
#import "UIView+Retrieval.h"

SpecBegin(WFSlideView)

__block WFSlideView *slideView;
__block id delegate;

beforeEach(^{
  delegate = OCMProtocolMock(@protocol(WFSlideViewDelegate));
  slideView = [[WFSlideView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  slideView.delegate = delegate;
  LTAddViewToWindow(slideView);
  [slideView layoutIfNeeded];
});

it(@"should have valid defaults", ^{
  expect(slideView.outgoingView).to.beNil();
  expect(slideView.incomingView).to.beNil();
  expect(slideView.progress).to.equal(0);
  expect(slideView.transition).to.equal(WFSlideViewTransitionCurtain);
  expect(slideView.panEnabled).to.beTruthy();
  expect(slideView.swipeEnabled).to.beTruthy();
  expect(slideView.progressIndicatorEnabled).to.beFalsy();
  expect(slideView.animatingLayers).toNot.beNil();
  expect(slideView.progressIndicatorColor).to.equal([UIColor blackColor]);
});

context(@"progress indicator", ^{
  __block UIView *progressIndicatorView;

  beforeEach(^{
    progressIndicatorView =
        (UIView *)[slideView wf_viewForAccessibilityIdentifier:@"ProgressIndicator"];
  });

  it(@"should create view", ^{
    expect(progressIndicatorView).to.beKindOf(UIView.class);
  });

  it(@"should change visibility of progress indicator", ^{
    slideView.progressIndicatorEnabled = NO;
    expect(progressIndicatorView.hidden).to.beTruthy();
    slideView.progressIndicatorEnabled = YES;
    expect(progressIndicatorView.hidden).to.beFalsy();
  });
});

context(@"delegate", ^{
  __block id panBeginGesture;
  __block id panEndGesture;

  beforeEach(^{
    panBeginGesture = OCMClassMock([UIPanGestureRecognizer class]);
    OCMStub([panBeginGesture translationInView:OCMOCK_ANY]).andReturn(CGPointMake(20, 0));
    OCMStub([panBeginGesture velocityInView:OCMOCK_ANY]).andReturn(CGPointMake(10, 0));
    OCMStub([panBeginGesture state]).andReturn(UIGestureRecognizerStateBegan);

    panEndGesture = OCMClassMock([UIPanGestureRecognizer class]);
    OCMStub([panEndGesture translationInView:OCMOCK_ANY]).andReturn(CGPointMake(30, 0));
    OCMStub([panEndGesture velocityInView:OCMOCK_ANY]).andReturn(CGPointMake(20, 0));
    OCMStub([panEndGesture state]).andReturn(UIGestureRecognizerStateEnded);
  });

  it(@"should call delegate when panning", ^{
    expect(slideView.progress).to.equal(0);

    [slideView didPan:panBeginGesture];
    OCMVerify([delegate slideViewDidBeginSlide:slideView]);
    expect(slideView.progress).to.beGreaterThan(0);

    OCMExpect([delegate slideViewDidEndSlide:slideView]);
    OCMExpect([delegate slideViewDidEndSlideAnimation:slideView]);

    [UIView performWithoutAnimation:^{
      [slideView didPan:panEndGesture];
    }];

    expect(slideView.progress).to.equal(1);
    OCMVerifyAllWithDelay(delegate, 0.5);
  });
});

context(@"animations", ^{
  it(@"should have no animating layers when not animating", ^{
    expect(slideView.animatingLayers).to.equal(@[]);
  });

  it(@"should have correct animating layers during animation", ^{
    [UIView animateWithDuration:0.1 animations:^{
      slideView.progress = 1;
      [slideView layoutIfNeeded];
    }];
    expect(slideView.animatingLayers.count).toNot.equal(0);

    NSMutableArray<CALayer *> *animatingLayers = [NSMutableArray array];
    [slideView.layer wf_enumerateLayersUsingBlock:^(CALayer *layer) {
      if (layer.animationKeys.count) {
        [animatingLayers addObject:layer];
      }
    }];

    NSSet *returnedAnimatingLayers = [NSSet setWithArray:slideView.animatingLayers];
    NSSet *expectedAnimatingLayers = [NSSet setWithArray:animatingLayers];

    expect(returnedAnimatingLayers).to.equal(expectedAnimatingLayers);
  });

  it(@"should have no animating layers after animation finishes", ^{
    [UIView animateWithDuration:0.1 animations:^{
      slideView.progress = 1;
      [slideView layoutIfNeeded];
    }];
    expect(slideView.animatingLayers.count).notTo.equal(0);
    expect(slideView.animatingLayers.count).will.equal(0);
  });
});

SpecEnd
