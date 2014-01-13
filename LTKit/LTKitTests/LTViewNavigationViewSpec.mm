// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTViewNavigationView.h"

#import "LTCGExtensions.h"
#import "LTTestUtils.h"

@interface LTViewNavigationView ()

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *contentView;

@end

SpecBegin(LTViewNavigationView)

const CGFloat kScale = 100;
const CGSize kViewSize = CGSizeMake(1, 2) * kScale;
const CGSize kContentSize = CGSizeMake(6, 4) * kScale;
const CGRect kViewFrame = CGRectFromOriginAndSize(CGPointZero, kViewSize);

context(@"initialization", ^{
  it(@"should initialize without state", ^{
    LTViewNavigationView *view = [[LTViewNavigationView alloc] initWithFrame:kViewFrame
                                                                 contentSize:kContentSize];
    expect(view.frame).to.equal(kViewFrame);
    expect(view.contentSize).to.equal(kContentSize);
  });
  
  it(@"should initialize with state", ^{
    const CGRect targetRect = CGRectFromOriginAndSize(CGPointMake(kScale,kScale), kViewSize);
    LTViewNavigationView *view = [[LTViewNavigationView alloc] initWithFrame:kViewFrame
                                                                 contentSize:kContentSize];
    [view zoomToRect:targetRect animated:NO];
    LTViewNavigationView *otherView = [[LTViewNavigationView alloc] initWithFrame:kViewFrame
                                                                      contentSize:kContentSize
                                                                            state:view.state];
    expect(view.frame).to.equal(kViewFrame);
    expect(view.contentSize).to.equal(kContentSize);
    expect(otherView.visibleContentRect).to.equal(view.visibleContentRect);
  });
});

context(@"properties", ^{
  __block LTViewNavigationView *view;
  
  beforeEach(^{
    view = [[LTViewNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize];
  });
  
  afterEach(^{
    view = nil;
  });
  
  it(@"should have default values", ^{
    expect(view.contentInset).to.equal(UIEdgeInsetsZero);
    expect(view.maxZoomScale).to.equal(CGFLOAT_MAX);
    expect(view.doubleTapLevels).to.equal(0);
    expect(view.doubleTapZoomFactor).to.equal(0);
    expect(view.mode).to.equal(LTViewNavigationFull);
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
  
  it(@"should set the padding", ^{
    const UIEdgeInsets kInsets = UIEdgeInsetsMake(5, 10, 15, 20);
    CGFloat oldZoomScale = view.zoomScale;
    view.contentInset = kInsets;
    expect(view.contentInset).to.equal(kInsets);
    expect(view.zoomScale).to.beLessThan(oldZoomScale);
  });
  
  it(@"should set the maxZoomScale", ^{
    const CGFloat kMaxZoomScale = 10;
    expect(view.zoomScale).to.beLessThan(kMaxZoomScale);
    
    CGFloat oldZoomScale = view.zoomScale;
    view.maxZoomScale = kMaxZoomScale;
    expect(view.maxZoomScale).to.equal(kMaxZoomScale);
    expect(view.zoomScale).to.equal(oldZoomScale);
  });
  
  it(@"should update zoom scale when setting the maxZoomScale while already zoomed to the max", ^{
    [view zoomToRect:CGRectMake(kScale, kScale, kScale, kScale) animated:NO];
    expect(view.zoomScale).to.beGreaterThan(view.scrollView.minimumZoomScale * 2);
    CGFloat oldZoomScale = view.zoomScale;
    view.maxZoomScale = oldZoomScale / 2;
    expect(view.maxZoomScale).to.equal(oldZoomScale / 2);
    expect(view.zoomScale).to.beCloseTo(oldZoomScale / 2);
  });
  
  it(@"should set the doubleTapLevels", ^{
    view.doubleTapLevels = 3;
    expect(view.doubleTapLevels).to.equal(3);
  });
  
  it(@"should set and clamp the doubleTapZoomFactor", ^{
    view.doubleTapZoomFactor = 3;
    expect(view.doubleTapZoomFactor).to.equal(3);
    view.doubleTapZoomFactor = -1;
    expect(view.doubleTapZoomFactor).to.equal(0);
  });
  
  it(@"should set the mode", ^{
    expect(view.scrollView.panGestureRecognizer.enabled).to.beTruthy();
    expect(view.scrollView.pinchGestureRecognizer.enabled).to.beTruthy();
    view.mode = LTViewNavigationNone;
    expect(view.mode).to.equal(LTViewNavigationNone);
    expect(view.scrollView.panGestureRecognizer.enabled).to.beFalsy();
    expect(view.scrollView.pinchGestureRecognizer.enabled).to.beFalsy();
  });
});

context(@"delegate", ^{
  __block LTViewNavigationView *view;
  __block id delegate;
  
  beforeEach(^{
    delegate = [OCMockObject mockForProtocol:@protocol(LTViewNavigationViewDelegate)];
    view = [[LTViewNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize];
    view.delegate = delegate;
  });
  
  afterEach(^{
    delegate = nil;
    view = nil;
  });
  
  it(@"should update the delegate on navigation", ^{
    const CGRect targetRect = CGRectFromOriginAndSize(CGPointZero, view.bounds.size);
    [[[delegate expect] ignoringNonObjectArgs] didNavigateToRect:targetRect];
    [view zoomToRect:targetRect animated:NO];
    [delegate verify];
  });
  
  it(@"should not update the delegate on navigation with animation", ^{
    const CGRect targetRect = CGRectFromOriginAndSize(CGPointZero, view.bounds.size);
    [[[delegate reject] ignoringNonObjectArgs] didNavigateToRect:targetRect];
    [view zoomToRect:targetRect animated:YES];
    [delegate verify];
  });
  
  if (LTRunningApplicationTests()) {
    xit(@"should not update the delegate on navigation with animation", ^{
      const CGRect targetRect = CGRectFromOriginAndSize(CGPointZero, view.bounds.size);
      __block BOOL delegateUpdated = NO;
      [[[[delegate stub] ignoringNonObjectArgs] andDo:^(NSInvocation *) {
        delegateUpdated = YES;
      }] didNavigateToRect:targetRect];
      [view zoomToRect:targetRect animated:YES];
      expect(delegateUpdated).will.beTruthy();
    });
  }
});

SpecEnd
