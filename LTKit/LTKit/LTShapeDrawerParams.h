// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPropertyMacros.h"

/// @class LTShapeDrawerParams
///
/// Holds the configurable parameters controlling the appearance of the shapes drawn by the
/// \c LTShapeDrawer.
@interface LTShapeDrawerParams : NSObject <NSCopying>

/// Line width of drawn strokes. Must be greater or equal to 1.
LTDeclareProperty(CGFloat, lineWidth, LineWidth);

/// Width of the shadow (at each side) around the the stroke. Must be non-negative.
LTDeclareProperty(CGFloat, shadowWidth, ShadowWidth);

/// Color of filled shapes. Must be in range [0,1].
LTDeclareProperty(GLKVector4, fillColor, FillColor);

/// Color of outlined shapes or paths. Must be in range [0,1].
LTDeclareProperty(GLKVector4, strokeColor, StrokeColor);

/// Color of the shadows around filled shapes, outlines, or strokes. Must be in range [0,1].
LTDeclareProperty(GLKVector4, shadowColor, ShadowColor);

/// Half the line width.
@property (readonly, nonatomic) CGFloat lineRadius;

@end
