// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTViewNavigationView.h"

#import "LTViewNavigationViewDelegate.h"

@interface LTViewNavigationView ()
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *contentView;
@end

@interface LTViewNavigationState ()
@property (nonatomic) CGPoint scrollViewContentOffset;
@property (nonatomic) UIEdgeInsets scrollViewContentInset;
@end

static CGPoint LTContentCenter(LTViewNavigationView *view) {
  CGRect contentFrame = [view.scrollView convertRect:view.contentView.frame toView:view];
  return std::round(CGRectCenter(CGRectIntersection(contentFrame, view.bounds)));
}

static BOOL LTSetHasSubclasses(NSSet *set, NSArray *classes) {
  for (Class aClass in classes) {
    if (![set objectsPassingTest:^BOOL(id obj, BOOL *) {
      return [obj isKindOfClass:aClass];
    }].count) {
      return NO;
    }
  }
  return YES;
}

SpecBegin(LTViewNavigationView)

const CGFloat kScale = 100;
const CGSize kViewSize = CGSizeMake(1, 2) * kScale;
const CGSize kContentSize = CGSizeMake(12, 8) * kScale;
const CGRect kViewFrame = CGRectFromOriginAndSize(CGPointZero, kViewSize);
const CGPoint kViewCenter = std::round(CGRectCenter(kViewFrame));
const CGFloat kContentScaleFactor = [UIScreen mainScreen].nativeScale;

context(@"initialization", ^{
  it(@"should initialize correctly with default navigation state", ^{
    LTViewNavigationView *view = [[LTViewNavigationView alloc] initWithFrame:kViewFrame
                                                                 contentSize:kContentSize
                                                          contentScaleFactor:kContentScaleFactor
                                                             navigationState:nil];
    expect(view.frame).to.equal(kViewFrame);
    expect(view.contentSize).to.equal(kContentSize);
    expect(view.contentScaleFactor).to.equal(kContentScaleFactor);
    expect(LTContentCenter(view)).to.equal(kViewCenter);
  });

  it(@"should initialize correctly with given navigation state", ^{
    const CGRect targetRect = CGRectFromOriginAndSize(CGPointMake(kScale,kScale), kViewSize);
    LTViewNavigationView *view = [[LTViewNavigationView alloc] initWithFrame:kViewFrame
                                                                 contentSize:kContentSize
                                                          contentScaleFactor:kContentScaleFactor
                                                             navigationState:nil];
    [view zoomToRect:targetRect animated:NO];
    LTViewNavigationView *otherView =
        [[LTViewNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize
                                 contentScaleFactor:kContentScaleFactor
                                    navigationState:view.navigationState];
    expect(view.frame).to.equal(kViewFrame);
    expect(view.contentSize).to.equal(kContentSize);
    expect(otherView.visibleContentRect).to.equal(view.visibleContentRect);
  });
});

context(@"properties", ^{
  __block LTViewNavigationView *view;
  
  beforeEach(^{
    view = [[LTViewNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize
                                    contentScaleFactor:kContentScaleFactor navigationState:nil];
  });
  
  afterEach(^{
    view = nil;
  });
  
  it(@"should have default values", ^{
    expect(view.maxZoomScale).to.equal(16);
    expect(view.navigationMode).to.equal(LTViewNavigationFull);
    expect(view.contentInset).to.equal(UIEdgeInsetsZero);
    expect(view.contentScaleFactor).to.equal([UIScreen mainScreen].nativeScale);
  });
  
  it(@"should set the content size", ^{
    CGFloat oldZoomScale = view.zoomScale;
    expect(oldZoomScale).to.beLessThan(1);
    view.contentSize = view.bounds.size * view.contentScaleFactor;
    expect(view.contentSize).to.equal(view.bounds.size * view.contentScaleFactor);
    expect(view.zoomScale).to.beCloseTo(1);
    view.contentSize = view.bounds.size * view.contentScaleFactor * 2;
    expect(view.contentSize).to.equal(view.bounds.size * view.contentScaleFactor * 2);
    expect(view.zoomScale).to.beCloseTo(0.5);
  });
  
  it(@"should set navigation mode", ^{
    expect(view.scrollView.panGestureRecognizer.enabled).to.beTruthy();
    expect(view.scrollView.pinchGestureRecognizer.enabled).to.beTruthy();
    view.navigationMode = LTViewNavigationNone;
    expect(view.navigationMode).to.equal(LTViewNavigationNone);
    expect(view.scrollView.panGestureRecognizer.enabled).to.beFalsy();
    expect(view.scrollView.pinchGestureRecognizer.enabled).to.beFalsy();
  });
  
  it(@"should return the correct viewForContentCoordinates", ^{
    expect(view.viewForContentCoordinates).to.beIdenticalTo(view.contentView);
  });

  it(@"should not have any attached gesture recognizers", ^{
    expect(view.gestureRecognizers).to.beNil();
  });

  it(@"should provide gesture recognizers for usage with possibly different views", ^{
    expect(view.navigationGestureRecognizers.count).to.beGreaterThan(0);
  });

  it(@"should not be able to modify the content scale factor", ^{
    view.contentScaleFactor = 1;
    expect(view.contentScaleFactor).to.equal(kContentScaleFactor);
  });
});

context(@"navigate", ^{
  const CGSize kViewSize = CGSizeMake(1, 2) * kScale;
  const CGSize kContentSize = CGSizeMake(12, 10) * kScale;
  const CGRect kViewFrame = CGRectFromOriginAndSize(CGPointZero, kViewSize);
  const CGRect targetRect = CGRectFromOriginAndSize(CGPointMake(kScale,kScale), kViewSize);

  __block LTViewNavigationView *view;

  beforeEach(^{
    view = [[LTViewNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize
                                    contentScaleFactor:kContentScaleFactor navigationState:nil];
  });

  afterEach(^{
    view = nil;
  });

  it(@"should navigate to state", ^{
    LTViewNavigationView *otherView =
        [[LTViewNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize
                                 contentScaleFactor:kContentScaleFactor navigationState:nil];

    expect(view.visibleContentRect).to.equal(otherView.visibleContentRect);

    [otherView zoomToRect:targetRect animated:NO];
    expect(view.visibleContentRect).notTo.equal(otherView.visibleContentRect);

    [view navigateToState:otherView.navigationState];
    expect(view.visibleContentRect).to.equal(otherView.visibleContentRect);
  });

  xit(@"should navigate to state with fractional offset values", ^{
    const CGRect targetRect = CGRectFromOriginAndSize(CGPointMake(kScale,kScale), kViewSize);
    LTViewNavigationView *view = [[LTViewNavigationView alloc] initWithFrame:kViewFrame
                                                                 contentSize:kContentSize
                                                          contentScaleFactor:kContentScaleFactor
                                                             navigationState:nil];
    [view zoomToRect:targetRect animated:NO];
    LTViewNavigationState *beforeState = view.navigationState;
    beforeState.scrollViewContentOffset =
        beforeState.scrollViewContentOffset + CGSizeMakeUniform(0.5);

    LTViewNavigationView *otherView =
        [[LTViewNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize
                                 contentScaleFactor:kContentScaleFactor navigationState:nil];
    [otherView navigateToState:beforeState];

    expect(otherView.navigationState).to.equal(beforeState);
    expect(otherView.navigationState).notTo.equal(view.navigationState);
  });

  it(@"should zoom to rect", ^{
    expect(view.visibleContentRect).notTo.equal(targetRect);
    [view zoomToRect:targetRect animated:NO];
    expect(view.visibleContentRect).to.equal(targetRect);
  });

  it(@"should zoom to rect with animation", ^{
    expect(view.visibleContentRect).notTo.equal(targetRect);
    [view zoomToRect:targetRect animated:YES];
    expect(view.visibleContentRect).notTo.equal(targetRect);
    expect(view.visibleContentRect).will.equal(targetRect);
  });
});

SpecEnd
