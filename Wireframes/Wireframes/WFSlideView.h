// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

NS_ASSUME_NONNULL_BEGIN

/// Possible types of transition between views, used by \c WFSlideView.
typedef NS_ENUM(NSUInteger, WFSlideViewTransition) {
  /// Incoming and outgoing views are separated by a sliding curtain. The slide direction is left
  /// to right.
  WFSlideViewTransitionCurtain,
  /// Incoming view slides in and pushes out the outgoing view.
  WFSlideViewTransitionSlide,
};

@class WFSlideView;

/// Protocol for reporting delegate events of \c WFSlideView.
@protocol WFSlideViewDelegate <NSObject>

@optional

/// Called when \c WFSlideView begins sliding by user gesture.
- (void)slideViewDidBeginSlide:(WFSlideView *)slideView;

/// Called when \c WFSlideView ends sliding by user gesture.
- (void)slideViewDidEndSlide:(WFSlideView *)slideView;

/// Called when \c WFSlideView ends sliding animation. Animation can continue after user's gesture
/// already ended in case swipe is enabled.
- (void)slideViewDidEndSlideAnimation:(WFSlideView *)slideView;

@end

/// View that slides an incoming view on top of an outgoing view, using different types
/// of transitions.
///
/// The view has progress indicator view with accessibility identifier "ProgressIndicator".
@interface WFSlideView : UIView

/// Handles the pan gesture. Allows the given pan \c gestureRecognizer to be used with this view.
/// The gesture will be handled as if it was performed on this view, regardless if pan is enabled or
/// not in this view.
- (void)didPan:(UIPanGestureRecognizer *)gestureRecognizer;

/// View that slides out.
@property (strong, nonatomic, nullable) UIView *outgoingView;

/// View that slides in.
@property (strong, nonatomic, nullable) UIView *incomingView;

/// Percentage of the \c incomingView being visible. Updated as a result of gestures taking place
/// (if enabled). Can be explicitly set to update the UI with the wanted progress. Silently clamped
/// to [0, 1]. Defaults to \c 0.
@property (nonatomic) CGFloat progress;

/// \c YES if progress indicator is shown during transition. \c NO by default.
/// It's purpose is to make the difference between two slides more noticeable.
@property (nonatomic) BOOL progressIndicatorEnabled;

/// Color of the progress indicator. Defaults to <tt>-[UIColor blackColor]</tt>.
@property (strong, nonatomic) UIColor *progressIndicatorColor;

/// Transition between the incoming and the outgoing view. \c WFSlideViewTransitionCurtain by
/// default.
@property (nonatomic) WFSlideViewTransition transition;

/// \c YES if pan gesture is enabled. \c YES by default.
@property (nonatomic) BOOL panEnabled;

/// \c YES if swipe gesture is enabled. \c YES by default. Has no effect if \c panEnabled is \c NO.
@property (nonatomic) BOOL swipeEnabled;

/// Array of \c CALayer objects that are currently involved in UIKit or Core Animation animations.
@property (readonly, nonatomic) NSArray<CALayer *> *animatingLayers;

/// Delegate.
@property (weak, nonatomic, nullable) id<WFSlideViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
