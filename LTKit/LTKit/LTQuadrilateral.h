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

/// Initializes a general quadrilateral defined by the given \c corners. In case of a simple (i.e.
/// non-self-intersecting) quadrilateral, the corners have to be provided in clockwise order.
- (instancetype)initWithCorners:(const LTQuadrilateralCorners &)corners;

/// Returns \c YES if the given \c point is contained by this quadrilateral.
- (BOOL)containsPoint:(CGPoint)point;

/// Rotates this instance by \c angle (which is provided in radians) in the XY plane around the
/// provided \c anchorPoint, in clockwise direction.
- (void)rotateByAngle:(CGFloat)angle aroundPoint:(CGPoint)anchorPoint;

/// Scales this instance by \c scaleFactor.
- (void)scale:(CGFloat)scaleFactor;

/// Translates this instance by \c translation.
- (void)translate:(CGPoint)translation;

/// First vertex of the quadrilateral.
@property (readonly, nonatomic) CGPoint v0;
/// Second vertex of the quadrilateral.
@property (readonly, nonatomic) CGPoint v1;
/// Third vertex of the quadrilateral.
@property (readonly, nonatomic) CGPoint v2;
/// Fourth vertex of the quadrilateral.
@property (readonly, nonatomic) CGPoint v3;

/// Rect that bounds the quadrilateral.
@property (readonly, nonatomic) CGRect boundingRect;

/// Center of this quadrilateral. The center is defined to be the average of the coordinates of the
/// corner points.
@property (readonly, nonatomic) CGPoint center;

/// Indicates whether this quadrilateral is convex.
@property (readonly, nonatomic) BOOL isConvex;

/// Indicates whether this quadrilateral is self-intersecting.
@property (readonly, nonatomic) BOOL isSelfIntersecting;

/// Transformation required to transform a rectangle with origin at (0, 0) and size (1, 1) such that
/// its projected corners coincide with the vertices of this quadrilateral.
@property (readonly, nonatomic) CATransform3D transform;

@end
