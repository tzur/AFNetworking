// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Protocol to be implemented by objects which should be informed about navigation events of the
/// content rectangle.
@protocol LTContentNavigationDelegate <NSObject>

@optional

/// Called when the content rectangle has been updated to the given \c visibleRect, be it due to
/// gestures on the content view or other programmatic updates of the content rectangle.
- (void)visibleContentDidNavigateToRect:(CGRect)visibleRect;

/// Called when a pan gesture was recognized on the content view.
- (void)panGestureOnContentViewRecognized;

/// Called when a pinch gesture was recognized on the content view.
- (void)pinchGestureOnContentViewRecognized;

/// Called when a double tap gesture was recognized on the content view.
- (void)doubleTapGestureOnContentViewRecognized;

@end

NS_ASSUME_NONNULL_END
