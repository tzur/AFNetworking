// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrush.h"

/// Possible painting modes for the \c LTRoundBrush and its subclasses.
typedef NS_ENUM(NSUInteger, LTRoundBrushMode) {
  /// Default mode, regular painting by adding to the existing values on the canvas.
  LTRoundBrushModePaint,
  /// Direct erasing mode, expected to be used with painters in \c LTPainterTargetModeDirectStroke
  /// mode when the target canvas contains positive values. Erasing is done by subtracting from the
  /// existing values on the canvas, clamping to zero. In this mode the opacity property controls
  /// the minimal clamping value, where opacity of \c 1 means erasing values to \c 0.
  LTRoundBrushModeEraseDirect,
  /// Indirect erasing mode, expected to be used with half float textures and painters in the
  /// \c LTPainterTargetModeSandboxedStroke mode. Erasing is done by subtracting values of the
  /// temporary texture to negative values, with the painter merging them. In this mode the opacity
  /// property controls the minimal clamping value, where opacity of \c 1 means erasing values to
  /// \c -1 (on the intermedieate texture).
  LTRoundBrushModeEraseIndirect,
  /// Painting by blending the current color with the existing color on the canvas. In this mode the
  /// hardness of the brush affects the alpha channel of the brush.
  LTRoundBrushModeBlend
};

/// A class representing a round brush used by the \c LTPainter, with hardness level controlling
/// whether the brush is solid / fuzzy (gaussian).
@interface LTRoundBrush : LTBrush

/// Controls whether the brush is painting or erasing, and how the opacity property is used.
@property (nonatomic) LTRoundBrushMode mode;

/// Fuzziness of the brush outline. Must be in range [0,1], default is \c 1.
@property (nonatomic) CGFloat hardness;
LTPropertyDeclare(CGFloat, hardness, Hardness)

@end
