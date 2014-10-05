// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <vector>

/// An array of three \c CGPoint representing the corners of a triangle.
typedef std::array<CGPoint, 3> LTTriangleCorners;

/// Represents a triangle in the XY plane.
@interface LTTriangle : NSObject

/// Initializes a triangle defined by the given corner points.
- (instancetype)initWithCorners:(const LTTriangleCorners &)corners;

/// Returns \c YES if the given \c point is contained by this triangle.
- (BOOL)containsPoint:(CGPoint)point;

/// First vertex of the triangle, in clockwise order.
@property (readonly, nonatomic) CGPoint v0;
/// Second vertex of the triangle, in clockwise order.
@property (readonly, nonatomic) CGPoint v1;
/// Third vertex of the triangle, in clockwise order.
@property (readonly, nonatomic) CGPoint v2;

@end
