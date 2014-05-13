// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawerShape.h"

/// @class LTShapeDrawerPathShape
///
/// A class used for drawing smooth anti-aliased pathes.
@interface LTShapeDrawerPathShape : LTShapeDrawerShape <LTDrawableShape>

/// Begins a new subpath at the specified point.
- (void)moveToPoint:(CGPoint)point;

/// Appends a straight line segment from the current point to the given point.
- (void)addLineToPoint:(CGPoint)point;

/// Closes the current subpath.
- (void)closePath;

/// Returns the current point of the current subpath.
@property (readonly, nonatomic) CGPoint currentPoint;

/// The translation of the shape (from the origin).
@property (nonatomic) CGPoint translation;

/// The rotation angle (clockwise, around the origin) of the shape.
@property (nonatomic) CGFloat rotationAngle;

@end
