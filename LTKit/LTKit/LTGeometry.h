// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Possible locations for a point relative to a ray.
typedef NS_ENUM(NSUInteger, LTPointLocation) {
  LTPointLocationRightOfRay,
  LTPointLocationLeftOfRay,
  LTPointLocationOnLineThroughRay
};

/// A pair of \c CGPoint.
typedef std::pair<CGPoint, CGPoint> CGPointPair;

/// Returns \c LTPointLocationRightOfRay if the given \c point lies on the right side of the ray
/// with the given \c origin and \c direction, \c LTPointLocationLeftOfRay if it lies on the left
/// side, and \c LTPointLocationOnLineThroughRay, otherwise.
LTPointLocation LTPointLocationRelativeToRay (CGPoint point, CGPoint origin, CGPoint direction);

/// Returns \c YES if the provided points are collinear.
BOOL LTPointsAreCollinear(const CGPoints &points);

/// Returns the result of rotating the given \c point in clockwise direction by \c angle around the
/// provided \c anchor point. The \c angle has to be given in radians.
CGPoint LTRotatePoint(CGPoint point, CGFloat angle, CGPoint anchor = CGPointZero);

/// Given a collection of \c CGPoints, returns \c YES if the polyline with edges
/// \c (points[0], points[1]), \c (points[1], points[2]), ... is self-intersecting. The provided
/// polyline is not required to be cyclic.
BOOL LTIsSelfIntersectingPolyline(const CGPoints &points);

/// Given a collection of \c CGPoints representing a polyline, returns a collection containing all
/// the intersection points of the polyline.
CGPoints LTComputeIntersectionPointsOfPolyLine(const CGPoints &points);

/// Given two collections of \c CGPoints representing two polylines \c polyline0 and \c polyline1,
/// returns a collection containing all the intersection points of \c polyline0 with \polyline1.
CGPoints LTComputeIntersectionPointsOfPolyLines(const CGPoints &polyline0,
                                                const CGPoints &polyline1);

/// Returns the intersection point of edge (p0, p1) and (q0, q1), if existing. Otherwise, returns
/// CGPointNull.
CGPoint LTIntersectionPointOfEdges(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1);

/// Returns the intersection point of the line passing through points \c p0 and \c p1 with the line
/// passing through \c q0 and \c q1, if existing. Otherwise, returns CGPointNull.
CGPoint LTIntersectionPointOfLines(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1);

/// Returns \c YES if the edge (p0, p1) intersects the edge (q0, q1).
BOOL LTEdgesIntersect(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1);

/// Returns the point on the line passing through \c pointOnLine and \c anotherPointOnLine with the
/// smallest distance to the given \c point.
CGPoint LTPointOnLineClosestToPoint(CGPoint pointOnLine, CGPoint anotherPointOnLine, CGPoint point);

/// Returns the point on the edge (\c p0, \c p1) with the smallest distance to the given \c point.
CGPoint LTPointOnEdgeClosestToPoint(CGPoint p0, CGPoint p1, CGPoint point);

/// Returns a pair (\c p, \c q) of points, s.t. \c p and \c q, respectively, are the points on edge
/// (\c p0, \c p1) and edge (\c q0, \c q1), respectively, with the minimum distance. If the given
/// edges intersect, the intersection point is used for both elements of the returned pair. If the
/// given edges conincide or are parallel, any pair of points with minimum distance is returned.
CGPointPair LTPointOnEdgeNearestToPointOnEdge(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1);

/// Returns a pair (\c p, \c q) of points, s.t. \c p and \c q, respectively, are the points on
/// \c polyline0 and  \c polyline1, respectively, with the minimum distance. If the given polylines
/// intersect, the intersection point is used for both elements of the returned pair. If the given
/// edges conincide or are parallel, any pair of points with minimum distance is returned.
CGPointPair LTPointOnPolylineNearestToPointOnPolyline(const CGPoints &polyline0,
                                                      const CGPoints &polyline1);

/// Returns the distance of the given \c point from the line passing through \c pointOnLine and
/// \c anotherPointOnLine.
CGFloat LTDistanceFromLine(CGPoint pointOnLine, CGPoint anotherPointOnLine, CGPoint point);
