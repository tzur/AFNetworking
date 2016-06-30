// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTNavigationView.h"

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
    expect(view.bounceToMinimumScale).to.beFalsy();
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

context(@"navigation", ^{
  const CGSize kViewSize = CGSizeMake(1, 2) * kScale;
  const CGSize kContentSize = CGSizeMake(12, 10) * kScale;
  const CGRect kViewFrame = CGRectFromSize(kViewSize);
  const CGRect targetRect = CGRectFromOriginAndSize(CGPointMake(kScale, kScale), kViewSize);

  __block LTNavigationView *view;

  beforeEach(^{
    view = [[LTNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize
                                contentScaleFactor:kContentScaleFactor navigationState:nil];
  });

  afterEach(^{
    view = nil;
  });

  context(@"LTContentNavigationManager", ^{
    it(@"should navigate to a given state", ^{
      LTNavigationView *otherView =
          [[LTNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize
                               contentScaleFactor:kContentScaleFactor navigationState:nil];

      expect(view.visibleContentRect).to.equal(otherView.visibleContentRect);

      [otherView zoomToRect:targetRect animated:NO];
      expect(view.visibleContentRect).notTo.equal(otherView.visibleContentRect);

      [view navigateToState:otherView.navigationState];
      expect(view.visibleContentRect).to.equal(otherView.visibleContentRect);
    });
  });

  it(@"should zoom to rect", ^{
    CGRect targetRectInPixels = CGRectFromOriginAndSize(targetRect.origin * kContentScaleFactor,
                                                        targetRect.size * kContentScaleFactor);
    expect(view.visibleContentRect).notTo.equal(targetRectInPixels);
    [view zoomToRect:targetRect animated:NO];
    expect(view.visibleContentRect).to.equal(targetRectInPixels);
  });

  it(@"should zoom to rect with animation", ^{
    CGRect targetRectInPixels = CGRectFromOriginAndSize(targetRect.origin * kContentScaleFactor,
                                                        targetRect.size * kContentScaleFactor);
    expect(view.visibleContentRect).notTo.equal(targetRectInPixels);
    [view zoomToRect:targetRect animated:YES];
    expect(view.visibleContentRect).notTo.equal(targetRectInPixels);
    expect(view.visibleContentRect).will.equal(targetRectInPixels);
  });
});

SpecEnd
