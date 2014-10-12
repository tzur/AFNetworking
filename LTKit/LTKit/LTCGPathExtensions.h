// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Augments every vertex of the provided \c path by a z coordinate of 1, multiplies the vertex with
/// the provided 3x3 \c transform matrix, projects the point back onto the z plane and returns the
/// resulting modified path.
CGMutablePathRef LTCGPathApplyTransform(CGPathRef path, GLKMatrix3 &transform);

/// Creates a path from the provided \c polyline. If \c closed is YES, a cyclic path is returned.
/// If \c smootheningRadius is greater than 0, additional control points are inserted to create a
/// smoother curve in the following way: Given two adjacent edges (v0, v1) and (v1, v2), two
/// additional control points w0 and w1 are inserted such that the path now starts with edge
/// (v0, w0), appends a quadratic curve from w0 to w1 with control point v1, and finally appends
/// edge (w1, v2). w0 and w1 lie on edges (v0, v1) and (v1, v2), respectively. The distance of w0
/// and w1 from v1 is min(smootheningRadius, length(v0, v1) / 2, length(v1, v2) / 2). This corner
/// smoothening is applied to every non-end joint of the provided \c polyline.
CGMutablePathRef LTCGPathCreateWithControlPoints(const LTVector2s &polyline,
                                                 CGFloat smootheningRadius, BOOL closed);
