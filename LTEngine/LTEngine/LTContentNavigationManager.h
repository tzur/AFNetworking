// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTContentNavigationState;

@protocol LTContentNavigationDelegate;

/// Protocol to be implemented by objects which manage the navigation of the content rectangle that
/// is displayed inside a suitable view.
@protocol LTContentNavigationManager <NSObject>

/// Updates the rectangle visible within the bounds of the enclosing view to be as close as possible
/// to the given \c rect, in floating-point pixel units of the content coordinate system.
- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated;

/// Navigates to the given navigation \c state. The \c state must have been extracted from an
/// \c id<LTContentNavigationManager> of the same class and with the same properties as this
/// instance, except for properties held by the given navigation \c state.
- (void)navigateToState:(LTContentNavigationState *)state;

/// Delegate to be informed about navigation events. Initial value is \c nil.
@property (weak, nonatomic) id<LTContentNavigationDelegate> navigationDelegate;

/// \c YES if this instance should cause the content rectangle to bounce to an aspect-fit state
/// inside its view at the end of any navigation request. Initial value is \c NO.
@property (nonatomic) BOOL bounceToAspectFit;

/// Multiplicative factor to adjust the minimum zoom scale for the content. A value of \c 1 causes
/// the content to be aspect-fit to the bounds of the view managed by this instance, upon minimum
/// zoom scale. Values lower than \c 1 allow the content to be proportionally smaller than the
/// aspect-fit rectangle, while values greater than \c 1 restrict the content to be proportionally
/// larger than the aspect-fit rectangle. Must be positive. Initial value is \c 1.
///
/// @important Attempts to set this property to values causing the content to be larger than allowed
/// by the view are silently ignored.
@property (nonatomic) CGFloat minZoomScaleFactor;

/// Current navigation state of this instance.
@property (readonly, nonatomic) LTContentNavigationState *navigationState;

@end

NS_ASSUME_NONNULL_END
