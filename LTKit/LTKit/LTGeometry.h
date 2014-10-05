// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Possible locations for a point relative to a ray.
typedef NS_ENUM(NSUInteger, LTPointLocation) {
  LTPointLocationRightOfRay,
  LTPointLocationLeftOfRay,
  LTPointLocationOnLineThroughRay
};

/// Returns \c LTPointLocationRightOfRay if the given \c point lies on the right side of the ray
/// with the given \c origin and \c direction, \c LTPointLocationLeftOfRay if it lies on the left
/// side, and \c LTPointLocationOnLineThroughRay, otherwise.
LTPointLocation LTPointLocationRelativeToRay (CGPoint point, CGPoint origin, CGPoint direction);

/// Returns \c YES if the provided points are collinear.
BOOL LTPointsAreCollinear(const CGPoints &points);

/// Returns the result of rotating the given \c point in clockwise direction by \c angle around the
/// provided \c anchor point. The \c angle has to be given in radians.
CGPoint LTRotatePoint(CGPoint point, CGFloat angle, CGPoint anchor = CGPointZero);

/// Given a collection of CGPoints, returns \c YES if the polyline with edges
/// \c (points[0], points[1]), \c (points[1], points[2]), ... is self-intersecting. The provided
/// polyline is not required to be cyclic.
BOOL LTIsSelfIntersectingPolyline(const CGPoints &points);

/// Given a collection of CGPoint's representing a polyline, returns a collection containing all the
/// intersection points of the polyline.
CGPoints LTComputeIntersectionPointsOfPolyLine(const CGPoints &points);

/// Returns the intersection point of edge (p0, p1) and (q0, q1), if existing, otherwise
/// CGPointNull.
CGPoint LTIntersectionPointOfEdges(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1);

/// Returns \c YES if the edge (p0, p1) intersects the edge (q0, q1).
BOOL LTEdgesIntersect(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1);
