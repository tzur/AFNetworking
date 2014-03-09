// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRoundBrush.h"

/// @class LTErasingBrush
///
/// A class representing a round eraser brush used by the \c LTPainter. The opacity property
/// controls the minimal clamping value, where opacity of \c 1 means erasing values to \c -1.
///
/// @note Due to the nature of this brush, it behaves correctly only when drawing to half-float
/// framebuffers, and in the \c LTPainterTargetModeSandboxedStroke mode.
@interface LTErasingBrush : LTRoundBrush
@end
