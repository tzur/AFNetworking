// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTViewNavigationMode.h"

/// This protocol is used to get updates on navigation events in real-time.
@protocol LTViewNavigationViewDelegate <NSObject>

/// Notify the delegate that the navigation view scrolled/zoomed to the current visible rectangle.
- (void)didNavigateToRect:(CGRect)visibleRect;

@end

/// This class represents the LTViewNavigationView's state at a given time, and can be used to
/// create additional views with the same zoom, offset, and visible rectangle as another LTView.
@interface LTViewNavigationState : NSObject
@end

/// This class imitates a UIScrollView containing a larger content view, and is used to simulate the
/// navigation behavior of the scroll view for the \c LTView class.
/// The delegate of this class is updated on every update to the content rectangle currently visible
/// through the scroll view.
@interface LTViewNavigationView : UIView

/// Initialize the navigation view with the given frame for a content with the given size (in
/// pixels), starting centered at the largest zoom level allowing the whole content to be visible
/// inside the scrollview.
- (id)initWithFrame:(CGRect)frame contentSize:(CGSize)contentSize;

/// Designated initializer: initialize the navigation view with the given frame for a content with
/// the given size (in pixels), starting at the given navigation state.
- (id)initWithFrame:(CGRect)frame contentSize:(CGSize)contentSize
              state:(LTViewNavigationState *)state;

// Notifies the view that it is about to be rotated to the given orientation due to an interface
// orientation change.
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation;

// Notifies the view that the rotation animation is about to start. This is called after the layout
// has been updated to reflect the new orientation.
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation;

/// The delegate will be updated whenever the visible content rectangle is changed.
@property (weak, nonatomic) id<LTViewNavigationViewDelegate> delegate;

/// Returns an array of the gesture recognizers used for navgiation.
@property (readonly, nonatomic) NSArray *navigationGestureRecognizers;

/// The size (in pixels) of the content.
@property (nonatomic) CGSize contentSize;

/// The distance between the content and the enclosing view.
@property (nonatomic) UIEdgeInsets contentInset;

/// The ratio of device screen pixels per content pixel at the maximal zoom level.
@property (nonatomic) CGFloat maxZoomScale;

/// The factor applied to the calculated minZoomScale (fits the image exactly inside the view).
/// Setting this to values smaller than 1 will make the image smaller than the view when fully
/// zoomed out, and vice versa. Default is 1.
@property (nonatomic) CGFloat minZoomScaleFactor;

// Number of different levels of zoom that the double tap switches between.
@property (nonatomic) NSUInteger doubleTapLevels;

// The zoom factor of the double tap gesture between the different levels. Double tapping will zoom
// to a scale of this factor multiplied by the previous zoom scale (except when in the maximal level
// which will zoom out to the minimal zoom scale).
@property (nonatomic) CGFloat doubleTapZoomFactor;

/// Returns the current state of the LTViewNavigationView, see \c LTViewNavigationState.
@property (readonly, nonatomic) LTViewNavigationState *state;

/// Returns the current visible rectangle of the content in the navigation view.
@property (readonly, nonatomic) CGRect visibleContentRect;

/// Returns the current zoom scale of the navigation view.
@property (readonly, nonatomic) CGFloat zoomScale;

/// Controls which navigation gestures are currently enabled, and the navigation behavior of the
/// view.
@property (nonatomic) LTViewNavigationMode mode;

/// A view that can be used for aquiring touch and gesture locations in content coordinates.
/// For example, the following will return the gesture location in content coordinates (in points):
/// @code
/// [gesture locationInView:ltView.viewForContentCoordinates]
/// @endcode
@property (readonly, nonatomic) UIView *viewForContentCoordinates;

@end

#pragma mark -
#pragma mark For Testing
#pragma mark -

@interface LTViewNavigationView (ForTesting)

/// Zooms to a specific area of the content so that it is visible in the receiver.
- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated;

@end
