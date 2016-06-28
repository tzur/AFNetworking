// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@protocol LTContentNavigationManager;

/// Protocol to be implemented by objects which should be informed about navigation events of the
/// content rectangle.
@protocol LTContentNavigationDelegate <NSObject>

@optional

/// Called when the given content navigation \c manager updated the visible content rectangle to the
/// given \c visibleRect, provided in floating-point pixel units of the content coordinate system,
/// be it due to gestures or programmatic updates of the content rectangle.
- (void)navigationManager:(id<LTContentNavigationManager>)manager
 didNavigateToVisibleRect:(CGRect)visibleRect;

/// Called to inform the delegate that the given navigation \c manager has finished handling the end
/// of a pan gesture.
- (void)navigationManagerDidHandlePanGesture:(id<LTContentNavigationManager>)manager;

/// Called to inform the delegate that the given navigation \c manager has finished handling the end
/// of a pinch gesture.
- (void)navigationManagerDidHandlePinchGesture:(id<LTContentNavigationManager>)manager;

/// Called to inform the delegate that the given navigation \c manager has finished handling the end
/// of a double tap gesture.
- (void)navigationManagerDidHandleDoubleTapGesture:(id<LTContentNavigationManager>)manager;

@end

NS_ASSUME_NONNULL_END
