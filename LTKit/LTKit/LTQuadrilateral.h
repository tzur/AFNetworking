// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// An array of four \c CGPoint representing the corners of a quadrilateral.
typedef std::array<CGPoint, 4> LTQuadrilateralCorners;

/// Represents a quadrilateral in the XY plane.
@interface LTQuadrilateral : NSObject

/// Returns a rectangular quadrilateral defined by the given \c rect.
+ (instancetype)quadrilateralFromRect:(CGRect)rect;

/// Returns a rectangular quadrilateral with the given \c origin and the given \c size.
+ (instancetype)quadrilateralFromRectWithOrigin:(CGPoint)origin andSize:(CGSize)size;

/// Initializes a general quadrilateral defined by the given corner points, in clockwise order.
- (instancetype)initWithCorners:(const LTQuadrilateralCorners &)corners;

/// First vertex of the quadrilateral, in clockwise order.
@property (readonly, nonatomic) CGPoint v0;
/// Second vertex of the quadrilateral, in clockwise order.
@property (readonly, nonatomic) CGPoint v1;
/// Third vertex of the quadrilateral, in clockwise order.
@property (readonly, nonatomic) CGPoint v2;
/// Fourth vertex of the quadrilateral, in clockwise order.
@property (readonly, nonatomic) CGPoint v3;

/// Rect that bounds the quadrilateral.
@property (readonly, nonatomic) CGRect boundingRect;

/// Indicates whether this quadrilateral is convex.
@property (readonly, nonatomic) BOOL isConvex;

/// Transformation required to transform a rectangle with origin at (0, 0) and size (1, 1) such that
/// its projected corners coincide with the vertices of this quadrilateral.
@property (readonly, nonatomic) CATransform3D transform;

@end
