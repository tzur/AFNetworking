// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCGExtensions.h"
#import "LTCommonDrawableShape.h"
#import "LTDrawableShape.h"

/// A class used for drawing filled 2D triangular meshes. This is usually used when drawing custom
/// shapes like arrows, rectangles, etc.
@interface LTShapeDrawerTriangularMeshShape : LTCommonDrawableShape <LTDrawableShape>

/// Fills the given triangle with shadows on the edges defined in the given mask.
- (void)fillTriangle:(CGTriangle)triangle withShadowOnEdges:(CGTriangleEdgeMask)edgeMask;

@end
