// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXPagingView.h"

/// Fake page view for testing.
@interface SPXFakeFocusAwarePageView : UIView<SPXFocusAwarePageView>
@property (nonatomic) NSUInteger didGainFocus;
@property (nonatomic) NSUInteger willLoseFocus;
@end

@implementation SPXFakeFocusAwarePageView

- (void)pageViewDidGainFocus {
  self.didGainFocus++;
}

- (void)pageViewWillLoseFocus {
  self.willLoseFocus++;
}

@end

/// Expose that \c SPXPagingView conforms to the protocol \c UIScrollViewDelegate for testing.
@interface SPXPagingView () <UIScrollViewDelegate>
@end

SpecBegin(SPXPagingView)
__block CGFloat pagingViewWidth;
__block SPXPagingView *pagingView;

beforeEach(^{
  pagingViewWidth = 500;
  pagingView = [[SPXPagingView alloc] initWithFrame:CGRectMake(0, 0, pagingViewWidth, 200)];
});

it(@"should initialize with scroll position set to zero", ^{
  expect(pagingView.scrollPosition).to.equal(@0);
});

context(@"setting page width ratio", ^{
  it(@"should set the page width correctly", ^{
    pagingView.pageViewWidthRatio = 0.3;
    expect(pagingView.pageViewWidthRatio).to.equal(0.3);
  });

  it(@"should clamp if the page width ratio is out of bounds ", ^{
    pagingView.pageViewWidthRatio = 1.1;
    expect(pagingView.pageViewWidthRatio).to.equal(1.0);
  });

  it(@"should clamp if the page width ratio is negative", ^{
    pagingView.pageViewWidthRatio = -0.3;
    expect(pagingView.pageViewWidthRatio).to.equal(0);
  });

  it(@"should not change scroll position", ^{
    pagingView.pageViews = @[
      [[UIView alloc] init],
      [[UIView alloc] init]
    ];
    [pagingView scrollToPage:1 animated:NO];

    pagingView.pageViewWidthRatio = 0.3;

    expect(pagingView.scrollPosition).to.equal(1);
  });
});

context(@"setting spcaing ratio", ^{
  it(@"should set the spacing ratio corrrectly ", ^{
    pagingView.spacingRatio = 0.3;
    expect(pagingView.spacingRatio).to.equal(0.3);
  });

  it(@"should clamp if the spacing ratio is out of bounds ", ^{
    pagingView.spacingRatio = 1.1;
    expect(pagingView.spacingRatio).to.equal(1.0);
  });

  it(@"should clamp if the spacing ratio is negative ", ^{
    pagingView.spacingRatio = -0.3;
    expect(pagingView.spacingRatio).to.equal(0);
  });

  it(@"should not change scroll position", ^{
    pagingView.pageViews = @[
      [[UIView alloc] init],
      [[UIView alloc] init]
    ];
    [pagingView scrollToPage:1 animated:NO];

    pagingView.spacingRatio = 0.3;

    expect(pagingView.scrollPosition).to.equal(1);
  });
});

context(@"scrolling", ^{
  it(@"should raise if the given page index is greater than the number of pages", ^{
    expect(^{
      [pagingView scrollToPage:1 animated:NO];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if the given page index is zero and there are no pages", ^{
    pagingView.pageViews = @[];
    expect(^{
      [pagingView scrollToPage:0 animated:NO];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should scroll to a given page index", ^{
    pagingView.pageViews = @[
      [[UIView alloc] init],
      [[UIView alloc] init]
    ];

    [pagingView scrollToPage:1 animated:NO];

    expect(pagingView.scrollPosition).to.equal(1);
  });

  it(@"should inform view on focus lose", ^{
    auto firstView = [[SPXFakeFocusAwarePageView alloc] init];
    pagingView.pageViews = @[
      firstView,
      [[UIView alloc] init]
    ];

    [pagingView scrollToPage:1 animated:NO];

    expect(firstView.willLoseFocus).to.beTruthy();
  });

  it(@"should inform view on focus gain", ^{
    auto secondView = [[SPXFakeFocusAwarePageView alloc] init];
    pagingView.pageViews = @[
      [[UIView alloc] init],
      secondView
    ];

    [pagingView scrollToPage:1 animated:NO];

    expect(secondView.didGainFocus).to.beTruthy();
  });

  it(@"should not inform view on focus lose if the focused view didn't change", ^{
    auto view = [[SPXFakeFocusAwarePageView alloc] init];
    pagingView.pageViews = @[view];

    [pagingView scrollToPage:0 animated:NO];

    expect(view.willLoseFocus).to.beFalsy();
  });

  it(@"should not inform view on focus gain if the focused view didn't change", ^{
    auto view = [[SPXFakeFocusAwarePageView alloc] init];
    pagingView.pageViews = @[view];

    [pagingView scrollToPage:0 animated:NO];

    expect(view.didGainFocus).to.equal(1);
  });
});

context(@"update pages", ^{
  it(@"should reset the scroll position", ^{
    pagingView.pageViews = @[
      [[UIView alloc] init],
      [[UIView alloc] init]
    ];
    [pagingView scrollToPage:1 animated:NO];

    pagingView.pageViews = @[[[UIView alloc] init]];

    expect(pagingView.scrollPosition).to.equal(0);
  });

  it(@"should inform first new view on focus gain", ^{
    auto secondView = [[SPXFakeFocusAwarePageView alloc] init];
    pagingView.pageViews = @[
      [[UIView alloc] init],
      secondView
    ];
    [pagingView scrollToPage:1 animated:NO];
    auto firstView = [[SPXFakeFocusAwarePageView alloc] init];

    pagingView.pageViews = @[firstView];

    expect(firstView.didGainFocus).to.beTruthy();
  });

  it(@"should inform view on focus lose", ^{
    auto view = [[SPXFakeFocusAwarePageView alloc] init];
    pagingView.pageViews = @[view];
    pagingView.pageViews = @[[[UIView alloc] init], view];

    expect(view.willLoseFocus).to.beTruthy();
  });

  it(@"should not inform view on focus lose if the focused view didn't change", ^{
    auto view = [[SPXFakeFocusAwarePageView alloc] init];
    pagingView.pageViews = @[view];
    pagingView.pageViews = @[view, [[UIView alloc] init]];

    expect(view.willLoseFocus).to.beFalsy();
  });

  it(@"should not inform view on focus gain if the focused view didn't change", ^{
    auto view = [[SPXFakeFocusAwarePageView alloc] init];
    pagingView.pageViews = @[view];
    pagingView.pageViews = @[view, [[UIView alloc] init]];

    expect(view.didGainFocus).to.equal(1);
  });
});

context(@"scroll view delegate", ^{
  __block UIScrollView *scrollView;
  __block CGFloat secondPageOffset;
  __block CGPoint point;

  beforeEach(^{
    scrollView = OCMClassMock([UIScrollView class]);
    secondPageOffset = pagingViewWidth * (pagingView.pageViewWidthRatio + pagingView.spacingRatio);
    pagingView.pageViews = @[
      [[UIView alloc] init],
      [[UIView alloc] init]
    ];
    [pagingView layoutIfNeeded];
  });

  it(@"should scroll to the next page if the velocity is positive", ^{
    point = CGPointMake(1, 0);
    [pagingView scrollViewWillEndDragging:scrollView withVelocity:CGPointMake(1, 0)
                      targetContentOffset:&point];

    expect(point.x).to.equal(secondPageOffset);
  });

  it(@"should scroll to the previous page if the velocity is negative", ^{
    point = CGPointMake(secondPageOffset - 1, 0);
    OCMStub([scrollView contentOffset]).andReturn(CGPointMake(secondPageOffset, 0));

    [pagingView scrollViewWillEndDragging:scrollView withVelocity:CGPointMake(-1, 0)
                      targetContentOffset:&point];

    expect(point.x).to.equal(0);
  });

  it(@"should clamp if the scrolling is out of bounds", ^{
    point = CGPointMake(secondPageOffset + 1, 0);
    OCMStub([scrollView contentOffset]).andReturn(CGPointMake(secondPageOffset, 0));

    [pagingView scrollViewWillEndDragging:scrollView withVelocity:CGPointMake(1, 0)
                      targetContentOffset:&point];

    expect(point.x).to.equal(secondPageOffset);
  });

  it(@"should scroll to the nearest page if the velocity is smaller than the threshold", ^{
    point = CGPointMake(150, 0);
    OCMStub([scrollView contentOffset]).andReturn(CGPointMake(150, 0));

    [pagingView scrollViewWillEndDragging:scrollView withVelocity:CGPointMake(0.005, 0)
                      targetContentOffset:&point];

    expect(point.x).to.equal(0);
  });
});

SpecEnd
