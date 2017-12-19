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

/// Scrolls to page with index \c pageIndex. If \c animated is \c YES the transition will be
/// animated. \c scrollPosition will be updated continuously during the scroll animation if
/// \c animated is \c YES, otherwise it will be updated once to the target \c pageIndex. Lose focus
/// and gain focus event handlers are invoked after the scrolling has finished. \c pageIndex must be
/// lower than the number of pages, otherwise an \c NSInvalidArgumentException is raised.
- (void)scrollToPage:(NSUInteger)pageIndex animated:(BOOL)animated;

/// Page views ordered horizontally from left to right, the current page view will always be snapped
/// to the center of the view. When providing two or more \c pageViews, the user will be able to
/// scroll between the pages, while the view bounces if past the edge. Reseting \c pageViews will
/// reset the focus to the first page and \c scrollPosition to \c 0. If any of the views conforms
/// to \c SPXFocusAwarePageView protocol it will receive focus gain and focus lose notifications.
@property (copy, nonatomic) NSArray<UIView *> *pageViews;

/// Spacing ratio between the page views, defined as the spacing width over the view width. Changing
/// this property will keep the currently focused page in focus and won't change \c scrollPosition.
/// Any value outside of the range <tt>[0, 1]</tt> will be clamped. Defaults to \c 0.05.
@property (nonatomic) CGFloat spacingRatio;

/// Page views width ratio, defined as the page width over the view width. Changing this property
/// will keep the currently focused page in focus and won't change \c scrollPosition. Any value
/// outside of the range <tt>[0, 1]</tt> will be clamped. Defaults to \c 0.84.
@property (nonatomic) CGFloat pageViewWidthRatio;

/// Scrolling position in range <tt>[0, pageViews.count - 1]</tt>. For example, if the center of the
/// second page is at the center of the paging view \c scrollPosition will be \c 1.0. KVO compliant,
/// changes are delivered on the main thread.
///
/// @note \c scrollPosition may be out of its bounds while bouncing - when it encounters a boundary
/// of the content.
@property (readonly, nonatomic) CGFloat scrollPosition;

@end

NS_ASSUME_NONNULL_END
