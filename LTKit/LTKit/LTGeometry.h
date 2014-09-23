// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Returns \c YES if a given point \c p lies on the right side of the ray originating from point
/// \c q and passing through point \c r.
BOOL LTPointLiesOnRightSideOfRay(CGPoint p, CGPoint q, CGPoint r);

/// Given a std::vector of GCPoints, returns \c YES if the polyline with edges
/// \c (points[0], points[1]), \c (points[1], points[2]), ... is self-intersecting.
BOOL LTIsSelfIntersectingPolyline(const CGPoints &points);

/// Returns \c YES if the edge (p0, p1) intersects the edge (q0, q1).
BOOL LTEdgesIntersect(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1);
