// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "WFSlideshowView.h"

SpecBegin(WFSlideshowView)

__block WFSlideshowView *slideshowView;

beforeEach(^{
  slideshowView = [[WFSlideshowView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
});

it(@"should have correct default values", ^{
  expect(slideshowView.transition).to.equal(WFSlideshowTransitionCurtain);
  expect(slideshowView.stillDuration).to.equal(1);
  expect(slideshowView.transitionDuration).to.equal(1);
});

context(@"delegate", ^{
  __block id delegate;

  beforeEach(^{
    delegate = OCMProtocolMock(@protocol(WFSlideshowViewDelegate));
  });

  context(@"setting the delegate", ^{
    it(@"should get number of slides from delegate when setting delegate", ^{
      slideshowView.delegate = delegate;

      OCMVerify([delegate numberOfSlidesInSlideshowView:slideshowView]);
    });

    it(@"should get slide from delegate when setting delegate with positive number of slides", ^{
      OCMStub([delegate numberOfSlidesInSlideshowView:slideshowView]).andReturn(2);

      slideshowView.delegate = delegate;

      OCMVerify([delegate slideshowView:slideshowView viewForSlideIndex:0]);
    });

    it(@"should not get slide from delegate when setting delegate with zero number of slides", ^{
      OCMStub([delegate numberOfSlidesInSlideshowView:slideshowView]).andReturn(0);
      OCMReject([[delegate ignoringNonObjectArgs] slideshowView:slideshowView viewForSlideIndex:0]);

      slideshowView.delegate = delegate;
    });
  });

  context(@"reloading slides", ^{
    beforeEach(^{
      slideshowView.delegate = delegate;
    });

    it(@"should get number of slides from delegate when reloading slides", ^{
      // Using OCMVerify in this test will always pass because of the delegate setting in the before
      // each block. Must use OCMExpect and OCMVerifyAll instead.
      OCMExpect([delegate numberOfSlidesInSlideshowView:slideshowView]);

      [slideshowView reloadSlides];

      OCMVerifyAll(delegate);
    });

    it(@"should get slide from delegate with positive number of slides when reloading slides", ^{
      OCMStub([delegate numberOfSlidesInSlideshowView:slideshowView]).andReturn(2);

      [slideshowView reloadSlides];

      OCMVerify([delegate slideshowView:slideshowView viewForSlideIndex:0]);
    });

    it(@"should not get slide from delegate with zero number of slides when reloading slides", ^{
      OCMStub([delegate numberOfSlidesInSlideshowView:slideshowView]).andReturn(0);
      OCMReject([[delegate ignoringNonObjectArgs] slideshowView:slideshowView viewForSlideIndex:0]);

      [slideshowView reloadSlides];
    });
  });

  context(@"setting the transition", ^{
    beforeEach(^{
      slideshowView.delegate = delegate;
    });

    it(@"should get number of slides from delegate when setting transition", ^{
      // Using OCMVerify in this test will always pass because of the delegate setting in the before
      // each block. Must use OCMExpect and OCMVerifyAll instead.
      OCMExpect([delegate numberOfSlidesInSlideshowView:slideshowView]);

      slideshowView.transition = WFSlideshowTransitionFade;

      OCMVerifyAll(delegate);
    });

    it(@"should get slide from delegate with positive number of slides when setting transition", ^{
      OCMStub([delegate numberOfSlidesInSlideshowView:slideshowView]).andReturn(2);

      slideshowView.transition = WFSlideshowTransitionFade;

      OCMVerify([delegate slideshowView:slideshowView viewForSlideIndex:0]);
    });

    it(@"should not get slide from delegate with zero number of slides when setting transition", ^{
      OCMStub([delegate numberOfSlidesInSlideshowView:slideshowView]).andReturn(0);
      OCMReject([[delegate ignoringNonObjectArgs] slideshowView:slideshowView viewForSlideIndex:0]);

      slideshowView.transition = WFSlideshowTransitionFade;
    });
  });

  context(@"transition", ^{
    __block UIView *firstView;
    __block UIView *secondView;

    beforeEach(^{
      firstView = [[UIView alloc] initWithFrame:CGRectZero];
      secondView = [[UIView alloc] initWithFrame:CGRectZero];
      OCMStub([delegate numberOfSlidesInSlideshowView:slideshowView]).andReturn(2);
      OCMStub([delegate slideshowView:slideshowView viewForSlideIndex:0]).andReturn(firstView);
      OCMStub([delegate slideshowView:slideshowView viewForSlideIndex:1]).andReturn(secondView);

      slideshowView.delegate = delegate;
    });

    it(@"should set received views as descendants of itself by default", ^{
      expect([firstView isDescendantOfView:slideshowView]).to.beTruthy();
      expect([secondView isDescendantOfView:slideshowView]).to.beTruthy();
    });

    it(@"should set received views as descendants of itself in fade transition", ^{
      slideshowView.transition = WFSlideshowTransitionFade;

      expect([firstView isDescendantOfView:slideshowView]).to.beTruthy();
      expect([secondView isDescendantOfView:slideshowView]).to.beTruthy();
    });

    it(@"should set received views as descendants of itself in curtain transition", ^{
      slideshowView.transition = WFSlideshowTransitionFade;
      slideshowView.transition = WFSlideshowTransitionCurtain;

      expect([firstView isDescendantOfView:slideshowView]).to.beTruthy();
      expect([secondView isDescendantOfView:slideshowView]).to.beTruthy();
    });
  });
});

SpecEnd
