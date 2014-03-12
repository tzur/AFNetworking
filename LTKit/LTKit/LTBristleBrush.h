// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrush.h"

/// Shape of the \c LTBristleBrush.
typedef NS_ENUM(NSUInteger, LTBristleBrushShape) {
  LTBristleBrushShapeRound = 0
};

/// @class LTBristleBrushShape
///
/// A class representing a brush with bristles tip, used by the \c LTPainter.
/// The brush shape, the number of bristles, their thickness, and their intensity are configurable.
///
/// @note Since the bristles are usually small, the default value of the spacing property is
/// changed to 0.01 to create a continuous brush.
@interface LTBristleBrush : LTBrush

/// Shape of the brush.
@property (nonatomic) LTBristleBrushShape shape;

/// Number of bristles in the brush. Must be in rane [2,100].
LTBoundedPrimitiveProperty(NSUInteger, bristles, Bristles);

/// Thickness of the bristles. Must be in range [0,2]. Default is 0.1.
LTBoundedPrimitiveProperty(CGFloat, thickness, Thickness);

@end
