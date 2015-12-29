// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTEAGLView.h"

#import "LTGLContext.h"

SpecBegin(LTEAGLView)

static CGSize kSize = CGSizeMake(10, 30);

__block LTGLContext *glContext;

__block LTEAGLView *view;
__block id delegate;

beforeEach(^{
  glContext = [LTGLContext currentContext];
  view = [[LTEAGLView alloc] initWithFrame:CGRectMake(0, 0, kSize.width, kSize.height)
                                   context:glContext];

  delegate = OCMProtocolMock(@protocol(LTEAGLViewDelegate));
  view.delegate = delegate;

  LTAddViewToWindow(view);
});

it(@"should initialize with context", ^{
  expect(view.context).to.equal(glContext);
});

it(@"should initially have a zero drawable size", ^{
  expect(view.drawableSize).to.equal(CGSizeZero);
});

it(@"should have a valid drawable size after layout", ^{
  [view layoutIfNeeded];
  expect(view.drawableSize).to.equal(std::floor(view.contentScaleFactor * kSize));
});

it(@"should initialize and layout with zero size", ^{
  view = [[LTEAGLView alloc] initWithFrame:CGRectZero context:glContext];
  expect(view.drawableSize).to.equal(CGSizeZero);
  [view layoutIfNeeded];
  expect(view.drawableSize).to.equal(CGSizeZero);
});

it(@"should initialize with default values", ^{
  expect(view.opaque).to.beTruthy();
  expect(view.contentScaleFactor).to.equal([UIScreen mainScreen].nativeScale);
});

it(@"should create drawable with integral size for fractional content scale factor", ^{
  view.contentScaleFactor = 2.66;
  [view layoutIfNeeded];
  expect(view.drawableSize).to.equal(std::floor(view.contentScaleFactor * kSize));
});

context(@"delegate", ^{
  it(@"should call delegate after calling setNeedsDisplay", ^{
    [[[delegate expect] ignoringNonObjectArgs] eaglView:view drawInRect:CGRectZero];

    [view setNeedsDisplay];

    // \c DBL_EPSILON to make sure we spin the runloop once.
    OCMVerifyAllWithDelay(delegate, DBL_EPSILON);
  });

  it(@"should not call delegate when app is no longer active", ^{
    [[[delegate reject] ignoringNonObjectArgs] eaglView:view drawInRect:CGRectZero];

    [[NSNotificationCenter defaultCenter]
     postNotificationName:UIApplicationWillResignActiveNotification
     object:nil];
    [view setNeedsDisplay];

    OCMVerifyAllWithDelay(delegate, DBL_EPSILON);
  });

  it(@"should call delegate when app becomes active", ^{
    [[[delegate expect] ignoringNonObjectArgs] eaglView:view drawInRect:CGRectZero];

    [[NSNotificationCenter defaultCenter]
     postNotificationName:UIApplicationWillResignActiveNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:UIApplicationDidBecomeActiveNotification
     object:nil];

    // \c DBL_EPSILON to make sure we spin the runloop once.
    OCMVerifyAllWithDelay(delegate, DBL_EPSILON);
  });
});

context(@"bounds change", ^{
  static CGSize kNewSize = CGSizeMake(73, 46);

  beforeEach(^{
    view.frame = CGRectMake(0, 0, kNewSize.width, kNewSize.height);
  });

  it(@"should change drawable size after layout", ^{
    [view layoutIfNeeded];
    expect(view.drawableSize).to.equal(std::floor(view.contentScaleFactor * kNewSize));
  });

  it(@"should call delegate after layout", ^{
    [[[delegate expect] ignoringNonObjectArgs] eaglView:view drawInRect:CGRectZero];

    [view layoutIfNeeded];

    // \c DBL_EPSILON to make sure we spin the runloop once.
    OCMVerifyAllWithDelay(delegate, DBL_EPSILON);
  });

  it(@"should change bounds from non-zero size to zero size", ^{
    [view layoutIfNeeded];
    view.frame = CGRectZero;
    [view layoutIfNeeded];
    expect(view.drawableSize).to.equal(CGSizeZero);
  });
});

SpecEnd
