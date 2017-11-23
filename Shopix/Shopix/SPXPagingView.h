// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for handling focus and unfocus page events.
@protocol SPXFocusAwarePageView <NSObject>

/// Invoked when the page view gains focus.
- (void)pageViewDidGainFocus;

/// Invoked when the page view loses focus.
- (void)pageViewWillLoseFocus;

@end

/// View that lets the user paginate horizontally between given views.
/// Unlike \c UIPageViewController this view does not limit the pages width to be exactly the same
/// as the controller's view size.
@interface SPXPagingView : UIView

- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

/// Page views ordered horizontally from left to right, the current page view will always be snapped
/// to the center of the view. When providing two or more \c pageViews, the user will be able to
/// scroll between the pages, while the view bounces if past the edge. Reseting \c pageViews will
/// reset the focus to the first page. If any of the views conforms to \c SPXFocusAwarePageView
/// protocol it will receive focus gain and focus lose notifications.
@property (copy, nonatomic) NSArray<UIView *> *pageViews;

/// Spacing ratio between the page views, defined as the spacing width over the view width. Any
/// value outside of the range <tt>[0, 1]</tt> will be clamped. Defaults to \c 0.05.
@property (nonatomic) CGFloat spacingRatio;

/// Page views width ratio, defined as the page width over the view width. Any value outside of the
/// range <tt>[0, 1]</tt> will be clamped. Defaults to \c 0.84.
@property (nonatomic) CGFloat pageViewWidthRatio;

@end

NS_ASSUME_NONNULL_END
