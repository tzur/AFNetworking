// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTNavigationView.h"

#import "LTContentNavigationManagerExamples.h"

@interface LTNavigationView ()
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *contentView;
@end

@interface LTNavigationViewState ()
@property (nonatomic) CGPoint scrollViewContentOffset;
@property (nonatomic) UIEdgeInsets scrollViewContentInset;
@end

static CGPoint LTContentCenter(LTNavigationView *view) {
  CGRect contentFrame = [view.scrollView convertRect:view.contentView.frame toView:view];
  return std::round(CGRectCenter(CGRectIntersection(contentFrame, view.bounds)));
}

SpecBegin(LTNavigationView)

const CGFloat kScale = 100;
const CGSize kViewSize = CGSizeMake(1, 2) * kScale;
const CGSize kContentSize = CGSizeMake(12, 8) * kScale;
const CGRect kViewFrame = CGRectFromSize(kViewSize);
const CGPoint kViewCenter = std::round(CGRectCenter(kViewFrame));
const CGFloat kContentScaleFactor = 3;

context(@"initialization", ^{
  it(@"should initialize correctly with default navigation state", ^{
    LTNavigationView *view = [[LTNavigationView alloc] initWithFrame:kViewFrame
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
    LTNavigationView *view = [[LTNavigationView alloc] initWithFrame:kViewFrame
                                                         contentSize:kContentSize
                                                  contentScaleFactor:kContentScaleFactor
                                                     navigationState:nil];
    [view zoomToRect:targetRect animated:NO];
    LTNavigationView *otherView =
        [[LTNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize
                             contentScaleFactor:kContentScaleFactor
                                navigationState:(LTNavigationViewState *)view.navigationState];
    expect(view.frame).to.equal(kViewFrame);
    expect(view.contentSize).to.equal(kContentSize);
    expect(otherView.visibleContentRect).to.equal(view.visibleContentRect);
  });
});

context(@"properties", ^{
  __block LTNavigationView *view;
  
  beforeEach(^{
    view = [[LTNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize
                                contentScaleFactor:kContentScaleFactor navigationState:nil];
  });
  
  afterEach(^{
    view = nil;
  });
  
  it(@"should have default values", ^{
    expect(view.contentSize).to.equal(kContentSize);
    expect(view.interactionModeProvider).to.beNil();
    expect(view.delegate).to.beNil();
    expect(view.panGestureRecognizer).toNot.beNil();
    expect(view.pinchGestureRecognizer).toNot.beNil();
    expect(view.doubleTapGestureRecognizer).toNot.beNil();

    // LTContentLocationProvider protocol.
    expect(view.contentScaleFactor).to.equal(kContentScaleFactor);
    expect(view.contentInset).to.equal(UIEdgeInsetsZero);
    expect(view.maxZoomScale).to.equal(16);
    expect(view.zoomScale).to.beCloseTo(0.25);

    // LTContentNavigationManager protocol.
    expect(view.navigationDelegate).to.beNil();
    expect(view.bounceToAspectFit).to.beFalsy();
    expect(view.navigationState).toNot.beNil();
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

  it(@"should not have any attached gesture recognizers", ^{
    expect(view.gestureRecognizers).to.beNil();
  });

  it(@"should not be able to modify the content scale factor", ^{
    view.contentScaleFactor = kContentScaleFactor * 2;
    expect(view.contentScaleFactor).to.equal(kContentScaleFactor);
  });
});

context(@"LTContentNavigationManager", ^{
  static const CGSize kViewSize = CGSizeMake(10, 20);
  static const CGRect kViewFrame = CGRectFromSize(kViewSize);
  static const CGSize kContentSize = CGSizeMakeUniform(100);
  static const CGRect kTargetRect = CGRectMake(25, 0, 50, 100);
  static const CGRect kUnreachableTargetRect = CGRectMake(-1, 0, 50, 100);
  static const CGRect kExpectedRect = CGRectMake(0, 0, 50, 100);

  __block LTNavigationView *view;
  __block LTNavigationView *anotherView;

  beforeEach(^{
    view = [[LTNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize
                                contentScaleFactor:kContentScaleFactor navigationState:nil];
    anotherView = [[LTNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize
                                       contentScaleFactor:kContentScaleFactor navigationState:nil];
  });

  afterEach(^{
    anotherView = nil;
    view = nil;
  });

  itShouldBehaveLike(kLTContentNavigationManagerExamples, ^{
    return @{
      kLTContentNavigationManager: view,
      kLTContentNavigationManagerReachableRect: $(kTargetRect),
      kLTContentNavigationManagerUnreachableRect: $(kUnreachableTargetRect),
      kLTContentNavigationManagerExpectedRect: $(kExpectedRect),
      kAnotherLTContentNavigationManager: anotherView
    };
  });
});

SpecEnd
