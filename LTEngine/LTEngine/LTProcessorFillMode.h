// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

/// This enumeration declares two general strategies to fill a target rectangle with a content of
/// source rectangle.
typedef NS_ENUM(NSUInteger, LTProcessorFillMode) {
  /// Stretch content from source rectangle onto the target rectangle.
  LTProcessorFillModeStretch = 0,
  /// Tile content from the source rectangle across the target rectangle.
  LTProcessorFillModeTile
};
