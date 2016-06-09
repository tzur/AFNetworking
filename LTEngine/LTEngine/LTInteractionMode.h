// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Options for interaction modes.
typedef NS_OPTIONS(NSUInteger, LTInteractionMode) {
  /// No recognition of gestures or raw touch events.
  LTInteractionModeNone = 0,
  /// Recognition of raw touch events is enabled.
  LTInteractionModeTouchEvents = 1 << 0,
  /// Tap gesture recognition is enabled.
  LTInteractionModeTap = 1 << 1,
  /// Pan gesture recognition is enabled.
  LTInteractionModePan = 1 << 2,
  /// Pinch gesture recognition is enabled.
  LTInteractionModePinch = 1 << 3,
  /// Recognition of all gestures is enabled.
  LTInteractionModeAllGestures =
      LTInteractionModeTap | LTInteractionModePan | LTInteractionModePinch
};

NS_ASSUME_NONNULL_END
