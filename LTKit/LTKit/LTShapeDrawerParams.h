// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// @class LTShapeDrawerParams
///
/// Holds the configurable parameters controlling the appearance of the shapes drawn by the
/// \c LTShapeDrawer.
@interface LTShapeDrawerParams : NSObject <NSCopying>

/// Line width of drawn strokes. Must be greater or equal to 1.
@property (nonatomic) CGFloat lineWidth;

/// Width of the shadow (at each side) around the the stroke. Must be non-negative.
@property (nonatomic) CGFloat shadowWidth;

/// Color of filled shapes. Must be in range [0,1].
@property (nonatomic) GLKVector4 fillColor;

/// Color of outlined shapes or paths. Must be in range [0,1].
@property (nonatomic) GLKVector4 strokeColor;

/// Color of the shadows around filled shapes, outlines, or strokes. Must be in range [0,1].
@property (nonatomic) GLKVector4 shadowColor;

/// Half the line width.
@property (readonly, nonatomic) CGFloat lineRadius;

@end
