// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXPagingView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXPagingView () <UIScrollViewDelegate>

/// Hidden views for spacing between \c pageViews.
@property (strong, nonatomic) NSArray<UIView *> *paddingViews;

/// Content view that holding all the \c pageViews horizontally from left to right with padding
/// between them.
@property (readonly, nonatomic) UIView *contentView;

/// View that holds \c contentView and provides horizontal scrolling.
@property (readonly, nonatomic) UIScrollView *scrollView;

/// Currently focused page index, updated after the scroll view animation end declerating. Reset to
/// \c 0 when \c pageViews are updated.
@property (nonatomic) NSUInteger focusedPageIndex;

@end

@implementation SPXPagingView

/// Default spacing ratio, defined as the spacing width over the view width.
static const CGFloat kDefaultSpacingRatio = 0.05;

/// Default page view ratio, defined as the page width over the view width.
static const CGFloat kDefaultPageViewWidthRatio = 0.84;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _spacingRatio = kDefaultSpacingRatio;
    _pageViewWidthRatio = kDefaultPageViewWidthRatio;
    [self setup];
  }
  return self;
}

- (void)setup {
  [self setupScrollView];
  [self setupContentView];
  self.pageViews = @[];
}

- (void)setupScrollView {
  _scrollView = [[UIScrollView alloc] init];
  self.scrollView.showsHorizontalScrollIndicator = NO;
  self.scrollView.delegate = self;
  self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
  [self addSubview:self.scrollView];

  [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self);
  }];
}

- (void)setupContentView {
  _contentView = [[UIView alloc] init];
  [self.scrollView addSubview:self.contentView];

  [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.scrollView);
  }];
}

#pragma mark -
#pragma mark UIScrollViewDelegate
#pragma mark -

- (void)scrollViewDidEndDecelerating:(UIScrollView * __unused)scrollView {
  if (!self.pageViews.count) {
    return;
  }

  CGSize pageSize = self.pageViews.firstObject.frame.size;
  CGFloat spacingWidth = self.spacingRatio * self.scrollView.frame.size.width;
  CGFloat contentOffsetX = self.scrollView.contentOffset.x;

  auto leftMarginWidth = self.paddingViews.firstObject.frame.size.width;
  [self notifyFocusedPageOnFocusLose];
  self.focusedPageIndex = ((contentOffsetX + scrollView.frame.size.width / 2 - leftMarginWidth) /
                           (pageSize.width + spacingWidth));
  [self notifyFocusedPageOnFocusGain];
}

- (void)notifyFocusedPageOnFocusLose {
  auto focusedPage = self.pageViews[self.focusedPageIndex];
  if ([focusedPage conformsToProtocol:@protocol(SPXFocusAwarePageView)]) {
    [(id<SPXFocusAwarePageView>)focusedPage pageViewWillLoseFocus];
  }
}

- (void)notifyFocusedPageOnFocusGain {
  auto focusedPage = self.pageViews[self.focusedPageIndex];
  if ([focusedPage conformsToProtocol:@protocol(SPXFocusAwarePageView)]) {
    [(id<SPXFocusAwarePageView>)focusedPage pageViewDidGainFocus];
  }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {
  if (self.pageViews.count < 2) {
    return;
  }

  CGSize pageSize = self.pageViews.firstObject.frame.size;
  CGSize scrollViewSize = self.scrollView.frame.size;
  CGFloat spacingWidth = self.spacingRatio * scrollViewSize.width;

  CGFloat targetPageIndex =
      (scrollView.contentOffset.x + velocity.x) / (pageSize.width + spacingWidth);
  targetPageIndex = velocity.x > 0 ? ceil(targetPageIndex) : floor(targetPageIndex);
  targetPageIndex = std::clamp(targetPageIndex, 0, self.pageViews.count - 1);

  CGFloat marginWidth = (scrollViewSize.width - pageSize.width) / 2;
  targetContentOffset->x = self.pageViews[(NSUInteger)targetPageIndex].frame.origin.x - marginWidth;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setPageViews:(NSArray<UIView *> *)pageViews {
  [_pageViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  _pageViews = [pageViews copy];

  NSMutableArray<UIView *> *paddingViews =
      [NSMutableArray arrayWithCapacity:self.pageViews.count + 1];
  for (UIView *pageView in pageViews) {
    [self.contentView addSubview:pageView];
    [paddingViews addObject:[[UIView alloc] init]];
  }
  [paddingViews addObject:[[UIView alloc] init]];
  self.paddingViews = paddingViews;

  [self updatePageViewsConstraints];

  [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
  if (self.pageViews.count) {
    [self notifyFocusedPageOnFocusLose];
    self.focusedPageIndex = 0;
    [self notifyFocusedPageOnFocusGain];
  } else {
    self.focusedPageIndex = 0;
  }
}

- (void)updatePageViewsConstraints {
  [self.pageViews enumerateObjectsUsingBlock:^(UIView *pageView, NSUInteger index, BOOL *) {
    [self updatePageViewConstraints:pageView nextToView:self.paddingViews[index]];
  }];
}

- (void)updatePageViewConstraints:(UIView *)pageView nextToView:(UIView *)view {
  [pageView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.height.equalTo(self.scrollView);
    make.left.equalTo(view.mas_right);
    make.width.equalTo(self.scrollView).multipliedBy(self.pageViewWidthRatio);
  }];
}

- (void)setPaddingViews:(NSArray<UIView *> *)paddingViews {
  [_paddingViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  _paddingViews = [paddingViews copy];
  for (UIView *paddingView in paddingViews) {
    [self.contentView addSubview:paddingView];
    paddingView.hidden = YES;
  }

  [self updatePaddingViewsConstraints];
  [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.equalTo(nn(self.paddingViews.lastObject));
  }];
}

- (void)updatePaddingViewsConstraints {
  [self.paddingViews enumerateObjectsUsingBlock:^(UIView *paddingView, NSUInteger index, BOOL *) {
    UIView * _Nullable viewOnLeft = index ? self.pageViews[index - 1] : nil;
    BOOL isMarginView = index == 0 || index == self.paddingViews.count - 1;
    [self updatePaddingViewConstraints:paddingView nextToView:viewOnLeft isMargin:isMarginView];
  }];
}

- (void)updatePaddingViewConstraints:(UIView *)paddingView nextToView:(nullable UIView *)view
                            isMargin:(BOOL)isMargin {
  CGFloat marginRatio = (1 - self.pageViewWidthRatio) * 0.5;

  [paddingView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.height.equalTo(self.scrollView);
    make.left.equalTo(view ? view.mas_right : @0);
    make.width.equalTo(self.scrollView).multipliedBy(isMargin ? marginRatio : self.spacingRatio);
  }];
}

- (void)setSpacingRatio:(CGFloat)spacingRatio {
  _spacingRatio = std::clamp(spacingRatio, 0, 1);
  [self updatePaddingViewsConstraints];
}

- (void)setPageViewWidthRatio:(CGFloat)pageViewWidthRatio {
  _pageViewWidthRatio = std::clamp(pageViewWidthRatio, 0, 1);
  [self updatePageViewsConstraints];
  [self updatePaddingViewConstraints:nn(self.paddingViews.firstObject) nextToView:nil isMargin:YES];
  [self updatePaddingViewConstraints:nn(self.paddingViews.lastObject)
                          nextToView:self.pageViews.lastObject isMargin:YES];
}

@end

NS_ASSUME_NONNULL_END
