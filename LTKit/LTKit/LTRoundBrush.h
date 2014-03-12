// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrush.h"

/// @class LTRoundBrush
///
/// A class representing a round brush used by the \c LTPainter, with hardness level controlling
/// whether the brush is solid / fuzzy (gaussian).
@interface LTRoundBrush : LTBrush

/// Fuzziness of the brush outline. Must be in range [0,1], default is \c 1.
LTBoundedPrimitiveProperty(CGFloat, hardness, Hardness)

@end
