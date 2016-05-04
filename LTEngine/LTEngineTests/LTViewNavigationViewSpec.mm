// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTViewNavigationView.h"

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

context(@"initialization", ^{
  it(@"should initialize without state", ^{
    LTViewNavigationView *view = [[LTViewNavigationView alloc] initWithFrame:kViewFrame
                                                                 contentSize:kContentSize];
    expect(view.frame).to.equal(kViewFrame);
    expect(view.contentSize).to.equal(kContentSize);
    expect(LTContentCenter(view)).to.equal(kViewCenter);
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

  it(@"should initialize with state with fractional offset values", ^{
    const CGRect targetRect = CGRectFromOriginAndSize(CGPointMake(kScale,kScale), kViewSize);
    LTViewNavigationView *view = [[LTViewNavigationView alloc] initWithFrame:kViewFrame
                                                                 contentSize:kContentSize];
    [view zoomToRect:targetRect animated:NO];
    LTViewNavigationState *beforeState = view.state;
    beforeState.scrollViewContentOffset = beforeState.scrollViewContentOffset +
        CGSizeMakeUniform(0.5);

    LTViewNavigationView *otherView = [[LTViewNavigationView alloc] initWithFrame:kViewFrame
                                                                      contentSize:kContentSize
                                                                            state:beforeState];

    expect(otherView.state).to.equal(beforeState);
    expect(otherView.state).notTo.equal(view.state);
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
    expect(view.minZoomScaleFactor).to.equal(0);
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
  
  it(@"should set the minZoomScaleFactor", ^{
    const CGFloat kMinZoomScaleFactor = 0.5;
    CGFloat oldMinimumZoomScale = view.scrollView.minimumZoomScale;
    view.minZoomScaleFactor = kMinZoomScaleFactor;
    expect(view.minZoomScaleFactor).to.equal(kMinZoomScaleFactor);
    expect(view.scrollView.minimumZoomScale).to.equal(oldMinimumZoomScale * kMinZoomScaleFactor);
  });
  
  it(@"should set the maxZoomScale", ^{
    const CGFloat kMaxZoomScale = 10;
    expect(view.zoomScale).to.beLessThan(kMaxZoomScale);
    
    CGFloat oldZoomScale = view.zoomScale;
    view.maxZoomScale = kMaxZoomScale;
    expect(view.maxZoomScale).to.equal(kMaxZoomScale);
    expect(view.zoomScale).to.equal(oldZoomScale);
  });

  it(@"should only update zoom scale when setting the minZoomScaleFactor if fully zoomed out", ^{
    const CGFloat kMinZoomScaleFactor = 0.5;
    CGFloat oldZoomScale = view.zoomScale;
    expect(view.zoomScale).to.equal(view.scrollView.minimumZoomScale);
    view.minZoomScaleFactor = kMinZoomScaleFactor;
    expect(view.minZoomScaleFactor).to.equal(kMinZoomScaleFactor);
    expect(view.zoomScale).to.equal(oldZoomScale * 0.5);
    expect(LTContentCenter(view)).to.equal(kViewCenter);
    
    [view zoomToRect:CGRectMake(kScale, kScale, kScale, kScale) animated:NO];
    expect(view.zoomScale).to.beGreaterThan(view.scrollView.minimumZoomScale);
    oldZoomScale = view.zoomScale;
    view.minZoomScaleFactor /= 2;
    expect(view.minZoomScaleFactor).to.equal(kMinZoomScaleFactor / 2);
    expect(view.zoomScale).to.equal(oldZoomScale);
    expect(LTContentCenter(view)).to.equal(kViewCenter);
  });
  
  it(@"should update zoom scale when setting the maxZoomScale while already zoomed to the max", ^{
    [view zoomToRect:CGRectMake(kScale, kScale, kScale, kScale) animated:NO];
    expect(view.zoomScale).to.beGreaterThan(view.scrollView.minimumZoomScale * 2);
    expect(LTContentCenter(view)).to.equal(kViewCenter);
    CGFloat oldZoomScale = view.zoomScale;
    view.maxZoomScale = oldZoomScale / 2;
    expect(view.maxZoomScale).to.equal(oldZoomScale / 2);
    expect(view.zoomScale).to.beCloseTo(oldZoomScale / 2);
    expect(LTContentCenter(view)).to.equal(kViewCenter);
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
  
  it(@"should return the correct viewForContentCoordinates", ^{
    expect(view.viewForContentCoordinates).to.beIdenticalTo(view.contentView);
  });
});

context(@"navigate", ^{
  const CGSize kViewSize = CGSizeMake(1, 2) * kScale;
  const CGSize kContentSize = CGSizeMake(12, 10) * kScale;
  const CGRect kViewFrame = CGRectFromOriginAndSize(CGPointZero, kViewSize);
  const CGRect targetRect = CGRectFromOriginAndSize(CGPointMake(kScale,kScale), kViewSize);

  __block LTViewNavigationView *view;

  beforeEach(^{
    view = [[LTViewNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize];
  });

  afterEach(^{
    view = nil;
  });

  it(@"should navigate to state", ^{
    LTViewNavigationView *otherView = [[LTViewNavigationView alloc] initWithFrame:kViewFrame
                                                                      contentSize:kContentSize];

    expect(view.visibleContentRect).to.equal(otherView.visibleContentRect);

    [otherView zoomToRect:targetRect animated:NO];
    expect(view.visibleContentRect).notTo.equal(otherView.visibleContentRect);

    [view navigateToState:otherView.state];
    expect(view.visibleContentRect).to.equal(otherView.visibleContentRect);
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
    OCMVerifyAll(delegate);
  });
  
  it(@"should not update the delegate on navigation with animation", ^{
    const CGRect targetRect = CGRectFromOriginAndSize(CGPointZero, view.bounds.size);
    [[[delegate reject] ignoringNonObjectArgs] didNavigateToRect:targetRect];
    [view zoomToRect:targetRect animated:YES];
    OCMVerifyAll(delegate);
  });

  context(@"gesture recognizers change", ^{
    beforeEach(^{
      [[[delegate stub] ignoringNonObjectArgs] didNavigateToRect:CGRectZero];
    });

    context(@"mocked changes", ^{
      __block id scrollView;
      __block UIPanGestureRecognizer *panRecognizer;
      __block UIPinchGestureRecognizer *pinchRecognizer;

      beforeEach(^{
        panRecognizer = view.scrollView.panGestureRecognizer;
        pinchRecognizer = view.scrollView.pinchGestureRecognizer;

        id scrollView = OCMPartialMock(view.scrollView);
        OCMStub([scrollView panGestureRecognizer]).andDo(^(NSInvocation *invocation) {
          UIPanGestureRecognizer *recognizer = panRecognizer;
          [invocation setReturnValue:&recognizer];
        });
        OCMStub([scrollView pinchGestureRecognizer]).andDo(^(NSInvocation *invocation) {
          UIPinchGestureRecognizer *recognizer = pinchRecognizer;
          [invocation setReturnValue:&recognizer];
        });
      });

      afterEach(^{
        scrollView = nil;
        panRecognizer = nil;
        pinchRecognizer = nil;
      });

      it(@"should update delegate when scrollview pan recognizer is changed", ^{
        __block UIPanGestureRecognizer *oldRecognizer = panRecognizer;
        panRecognizer = [[UIPanGestureRecognizer alloc] init];

        OCMExpect([delegate navigationGestureRecognizersDidChangeFrom:
                  [OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 3 &&
                 [recognizers containsObject:oldRecognizer] &&
                 [recognizers containsObject:pinchRecognizer] &&
                 [recognizers containsObject:view.doubleTapGestureRecognizer];
        }] to:[OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 3 &&
                 [recognizers containsObject:panRecognizer] &&
                 [recognizers containsObject:pinchRecognizer] &&
                 [recognizers containsObject:view.doubleTapGestureRecognizer];
        }]]);

        view.contentSize = CGSizeMake(view.contentSize.height, view.contentSize.width);
        OCMVerifyAll(delegate);
      });

      it(@"should update delegate when scrollview pan recognizer is changed to/from nil", ^{
        __block UIPanGestureRecognizer *oldRecognizer = panRecognizer;
        panRecognizer = nil;

        OCMExpect([delegate navigationGestureRecognizersDidChangeFrom:
                  [OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 3 &&
                 [recognizers containsObject:oldRecognizer] &&
                 [recognizers containsObject:pinchRecognizer] &&
                 [recognizers containsObject:view.doubleTapGestureRecognizer];
        }] to:[OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 2 &&
                 [recognizers containsObject:pinchRecognizer] &&
                 [recognizers containsObject:view.doubleTapGestureRecognizer];
        }]]);
        view.contentSize = CGSizeMake(view.contentSize.height, view.contentSize.width);

        panRecognizer = [[UIPanGestureRecognizer alloc] init];
        OCMExpect([delegate navigationGestureRecognizersDidChangeFrom:
                  [OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 2 &&
                 [recognizers containsObject:pinchRecognizer] &&
                 [recognizers containsObject:view.doubleTapGestureRecognizer];
        }] to:[OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 3 &&
                 [recognizers containsObject:panRecognizer] &&
                 [recognizers containsObject:pinchRecognizer] &&
                 [recognizers containsObject:view.doubleTapGestureRecognizer];
        }]]);

        view.contentSize = CGSizeMake(view.contentSize.height, view.contentSize.width);
        OCMVerifyAll(delegate);
      });

      it(@"should update delegate when scrollview pinch recognizer is changed", ^{
        __block UIPinchGestureRecognizer *oldRecognizer = pinchRecognizer;
        pinchRecognizer = [[UIPinchGestureRecognizer alloc] init];

        OCMExpect([delegate navigationGestureRecognizersDidChangeFrom:
                  [OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 3 &&
                 [recognizers containsObject:panRecognizer] &&
                 [recognizers containsObject:oldRecognizer] &&
                 [recognizers containsObject:view.doubleTapGestureRecognizer];
        }] to:[OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 3 &&
                 [recognizers containsObject:panRecognizer] &&
                 [recognizers containsObject:pinchRecognizer] &&
                 [recognizers containsObject:view.doubleTapGestureRecognizer];
        }]]);

        view.contentSize = CGSizeMake(view.contentSize.height, view.contentSize.width);
        OCMVerifyAll(delegate);
      });

      it(@"should update delegate when scrollview pinch recognizer is changed from/to nil", ^{
        __block UIPinchGestureRecognizer *oldRecognizer = pinchRecognizer;
        pinchRecognizer = nil;

        OCMExpect([delegate navigationGestureRecognizersDidChangeFrom:
                  [OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 3 &&
                 [recognizers containsObject:panRecognizer] &&
                 [recognizers containsObject:oldRecognizer] &&
                 [recognizers containsObject:view.doubleTapGestureRecognizer];
        }] to:[OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 2 &&
                 [recognizers containsObject:panRecognizer] &&
                 [recognizers containsObject:view.doubleTapGestureRecognizer];
        }]]);
        view.contentSize = CGSizeMake(view.contentSize.height, view.contentSize.width);

        pinchRecognizer = [[UIPinchGestureRecognizer alloc] init];
        OCMExpect([delegate navigationGestureRecognizersDidChangeFrom:
                  [OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 2 &&
                 [recognizers containsObject:panRecognizer] &&
                 [recognizers containsObject:view.doubleTapGestureRecognizer];
        }] to:[OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 3 &&
                 [recognizers containsObject:panRecognizer] &&
                 [recognizers containsObject:pinchRecognizer] &&
                 [recognizers containsObject:view.doubleTapGestureRecognizer];
        }]]);

        view.contentSize = CGSizeMake(view.contentSize.height, view.contentSize.width);
        OCMVerifyAll(delegate);
      });
    });

    context(@"actual changes", ^{
      it(@"should update delegate when content size changes and disables zoom", ^{
        view.maxZoomScale = 20;

        OCMExpect([delegate navigationGestureRecognizersDidChangeFrom:
                  [OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 3 &&
                 LTSetHasSubclasses(recognizers, @[[UIPanGestureRecognizer class],
                                                   [UIPinchGestureRecognizer class],
                                                   [UITapGestureRecognizer class]]);
        }] to:[OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 2 &&
                 LTSetHasSubclasses(recognizers, @[[UIPanGestureRecognizer class],
                                                   [UITapGestureRecognizer class]]);
        }]]);

        view.contentSize = CGSizeMake(2, 2);
        OCMVerifyAll(delegate);
      });

      it(@"should update delegate when content size changes and enables zoom", ^{
        view.maxZoomScale = 20;

        OCMExpect([delegate navigationGestureRecognizersDidChangeFrom:
                  [OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 3 &&
                 LTSetHasSubclasses(recognizers, @[[UIPanGestureRecognizer class],
                                                   [UIPinchGestureRecognizer class],
                                                   [UITapGestureRecognizer class]]);
        }] to:[OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 2 &&
                 LTSetHasSubclasses(recognizers, @[[UIPanGestureRecognizer class],
                                                   [UITapGestureRecognizer class]]);
        }]]);

        view.contentSize = CGSizeMake(2, 2);

        OCMExpect([delegate navigationGestureRecognizersDidChangeFrom:
                  [OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 2 &&
                 LTSetHasSubclasses(recognizers, @[[UIPanGestureRecognizer class],
                                                   [UITapGestureRecognizer class]]);
        }] to:[OCMArg checkWithBlock:^BOOL(NSSet *recognizers) {
          return recognizers.count == 3 &&
                 LTSetHasSubclasses(recognizers, @[[UIPanGestureRecognizer class],
                                                   [UIPinchGestureRecognizer class],
                                                   [UITapGestureRecognizer class]]);
        }]]);

        view.contentSize = kContentSize;
        OCMVerifyAll(delegate);
      });
    });
  });
});

SpecEnd
