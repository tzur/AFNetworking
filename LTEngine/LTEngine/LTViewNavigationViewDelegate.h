// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Protocol which should be implemented by objects that are to be informed about navigation events
/// of a content location provider.
@protocol LTViewNavigationViewDelegate <NSObject>

/// Is called after the currently visible subregion of the content rectangle has been updated to
/// equal the given \c visibleRect.
- (void)didNavigateToRect:(CGRect)visibleRect;

/// Is called after a pan gesture has been performed.
- (void)userPanned;

/// Is called after a pinch gesture has been performed.
- (void)userPinched;

/// Is called after a double tap gesture has been performed.
- (void)userDoubleTapped;

@end

NS_ASSUME_NONNULL_END
