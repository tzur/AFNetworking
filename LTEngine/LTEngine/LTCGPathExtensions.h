// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Block used for sequentially inspecting the elements of a path.
typedef void (^LTPathInspectionBlock)(CGPathElementType type, std::vector<CGPoint> points);

/// Iterates over the control points of the given \c path and executes the given \c block for every
/// path element with the appropriate parameters. The given \c path must not be \c NULL. The given
/// \c block must not be \c nil.
void LTCGPathInspectWithBlock(CGPathRef path, LTPathInspectionBlock block);

/// Creates an immutable copy of the provided graphics \c path transformed by the provided
/// \c transformation matrix. The resulting path is computed by augmenting every vertex of the
/// provided \c path by a z coordinate of 1, multiplying the vertex with the provided 3x3
/// \c transformation matrix and projecting the point back onto the z plane. The caller is
/// responsible for releasing the returned path.
lt::Ref<CGPathRef> LTCGPathCreateCopyByTransformingPath(CGPathRef path, GLKMatrix3 &transformation);

/// Creates a copy of the provided \c path such that its bounding box corresponds to the given
/// \c rect. The caller is responsible for releasing the returned path.
lt::Ref<CGPathRef> LTCGPathCreateCopyInRect(CGPathRef path, CGRect rect);

/// Creates a path from the provided \c polyline. If \c closed is YES, a cyclic path is returned.
/// If \c smootheningRadius is greater than 0, additional control points are inserted to create a
/// smoother curve in the following way: Given two adjacent edges (v0, v1) and (v1, v2), two
/// additional control points w0 and w1 are inserted such that the path now starts with edge
/// (v0, w0), appends a quadratic curve from w0 to w1 with control point v1, and finally appends
/// edge (w1, v2). w0 and w1 lie on edges (v0, v1) and (v1, v2), respectively. The distance of w0
/// and w1 from v1 is min(smootheningRadius, length(v0, v1) / 2, length(v1, v2) / 2). This corner
/// smoothening is applied to every non-end joint of the provided \c polyline. The caller is
/// responsible for releasing the returned path.
lt::Ref<CGPathRef> LTCGPathCreateWithControlPoints(const LTVector2s &polyline,
                                                   CGFloat smootheningRadius, BOOL closed);

/// Creates a path from the provided \c polyline. If \c closed is YES, a cyclic path is returned.
/// If \c gapSize is greater than 0, the returned path contains gaps in the following way: Given an
/// edge (v0, v1), two additional control points w0 and w1 are inserted such that w0 and w1 lie on
/// (v0, v1) and the lengths of (v0, w0) and (w1, v1) equal \c min(gapSize, length(v0, v1) / 2). The
/// resulting path contains a line from w0 to w1, but no lines from v0 to w0 or from w1 to v1. This
/// procedure is applied to every edge of the polyline. The caller is responsible for releasing the
/// returned path.
lt::Ref<CGPathRef> LTCGPathCreateWithControlPointsAndGapsAroundVertices(const LTVector2s &polyline,
                                                                        CGFloat gapSize,
                                                                        BOOL closed);

/// Creates a path from the provided \c polyline. The given \c gapSize must be greater than \c 0.
/// The returned path is a closed path containing gaps in the following way: Given two adjacent
/// edges <tt>(v0, v1)</tt> and <tt>(v1, v2)</tt> of the given \c polyline, two additional points
/// \c a and \c b are added to the polyline such that \c a lies on <tt>(v0, v1)</tt>, \c b lies on
/// <tt>(v1, v2)</tt>, the length of <tt>(a, v1)</tt> equals
/// <tt>min(edgeLength, length(v0, v1) / 2)</tt>, and the length of
/// <tt>(v1, b)</tt> equals <tt>min(edgeLength, length(v1, v2) / 2)</tt>. The resulting path
/// contains the edges from \c a to \c v1 and from \c v1 to \c b, but no other edges originating
/// from \c a or \c b. This procedure is applied to every pair of adjacent edges of the \c polyline.
lt::Ref<CGPathRef> LTCGPathCreateWithControlPointsAndGapsOnEdges(const LTVector2s &polyline,
                                                                 CGFloat edgeLength);

/// Creates a path from the provided \c polyline. If \c closed is YES, a cyclic path is returned.
/// If \c circleRadius is greater than 0, the returned path contains empty circles of radius
/// \c circleRadius around its vertices. The caller is responsible for releasing the returned path.
lt::Ref<CGPathRef> LTCGPathCreateWithControlPointsAndCirclesAroundVertices(
    const LTVector2s &polyline, CGFloat circleRadius, BOOL closed);

/// Creates an immutable path constituting a sector of a circle with the given \c center and the
/// given \c radius. The arc of the sector is defined by the given \c startAngle and \c endAngle and
/// the \c clockwise parameter. Both \c startAngle and \c endAngle are measured in counter-clockwise
/// direction from the x-axis in the current user space. If \c clockwise is YES, the arc of the
/// sector is the arc between the starting point defined by \c startAngle and the ending point
/// defined by the \c endAngle in clockwise direction. Otherwise, the arc is the complementary arc.
/// The caller is responsible for releasing the returned path.
lt::Ref<CGPathRef> LTCGPathCreateWithCircularSector(LTVector2 center, CGFloat radius,
                                                    CGFloat startAngle, CGFloat endAngle,
                                                    BOOL clockwise = NO);
