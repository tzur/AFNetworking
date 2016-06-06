// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTContentNavigationState;

@protocol LTContentNavigationDelegate;

/// Protocol to be implemented by objects which manage the navigation of the content rectangle.
@protocol LTContentNavigationManager <NSObject>

/// Navigates to the given navigation \c state. The \c state must have been extracted from an
/// \c id<LTContentNavigationManager> of the same class and with the same properties as this
/// instance, except for properties held by the given navigation \c state.
- (void)navigateToState:(LTContentNavigationState *)state;

/// Updates the rectangle visible within the bounds of this instance to be the given \c rect, in
/// point units of the content coordinate system.
- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated;

/// Delegate to be informed about navigation events.
@property (weak, nonatomic) id<LTContentNavigationDelegate> navigationDelegate;

/// \c YES if this instance should cause the content rectangle to bounce to an aspect-fit state
/// inside its view at the end of any navigation request.
@property (nonatomic) BOOL bounceToMinimumScale;

/// Current navigation state of this instance.
@property (readonly, nonatomic) LTContentNavigationState *navigationState;

@end

NS_ASSUME_NONNULL_END
