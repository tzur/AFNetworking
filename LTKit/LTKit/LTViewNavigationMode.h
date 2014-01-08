// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

// This enum describes the possible states of navigation.
typedef enum : NSUInteger {
  /// Scrolling, zooming, and double tap are all enabled.
  LTViewNavigationFull = 0,
  /// Scrolling and zooming are enabled, while double tap is disabled.
  LTViewNavigationZoomAndScroll,
  /// Scrolling and zooming are enabled but bounce back to the minimal scale when the pinch/drag
  /// gesture ends. double tap is disabled.
  LTViewNavigationBounceToMinimalScale,
  /// Only two finger gestures are enabled for zooming and scrolling, and double tap is disabled.
  LTViewNavigationTwoFingers,
  /// Scrolling, zooming and double tap are all disabled.
  LTViewNavigationNone = 0,
} LTViewNavigationMode;
