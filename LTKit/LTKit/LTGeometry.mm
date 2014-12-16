// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTGeometry.h"

#import "LTGLKitExtensions.h"

static const CGFloat kEpsilon = 1e-6;

LTPointLocation LTPointLocationRelativeToRay (CGPoint point, CGPoint origin, CGPoint direction) {
  LTParameterAssert(direction != CGPointZero,
                    @"Parameter direction may not be the zero point.");
  CGPoint pointOnRayOtherThanOrigin = origin + direction;
  GLKMatrix3 matrix = GLKMatrix3Make(origin.x, origin.y, 1,
                                     pointOnRayOtherThanOrigin.x, pointOnRayOtherThanOrigin.y, 1,
                                     point.x, point.y, 1);
  CGFloat determinant = GLKMatrix3Determinant(matrix);
  if (std::abs(determinant) <= kEpsilon) {
    return LTPointLocationOnLineThroughRay;
  }
  if (determinant > kEpsilon) {
    return LTPointLocationRightOfRay;
  }
  return LTPointLocationLeftOfRay;
}

BOOL LTPointsAreCollinear(const CGPoints &points) {
  NSUInteger numPoints = points.size();
  if (numPoints <= 2) {
    return YES;
  }

  // For numerical stability, compute the longest vector originating at points[0] and passing
  // through another point in points. Note that in general, the (overall) longest vector should be
  // computed, which is not done at this point for efficiency and simplicity.
  CGPoint furthestPoint = points[1];
  CGFloat furthestPointDistanceSquared = CGPointDistanceSquared(furthestPoint, points[0]);
  for (CGPoints::size_type i = 2; i < numPoints; ++i) {
    CGFloat currentDistanceSquared = CGPointDistanceSquared(points[i], points[0]);
    if (currentDistanceSquared > furthestPointDistanceSquared) {
      furthestPoint = points[i];
      furthestPointDistanceSquared = currentDistanceSquared;
    }
  }
  if (furthestPointDistanceSquared <= kEpsilon * kEpsilon) {
    // All points are (almost) identical.
    return YES;
  }
  GLKVector3 line = GLKLineEquation(furthestPoint, points[0]);
  line = line / std::sqrt(line.x * line.x + line.y * line.y);
  for (const CGPoint &point : points) {
    if (std::abs(GLKVector3DotProduct(GLKVector3Make(point.x, point.y, 1), line)) > kEpsilon) {
      return NO;
    }
  }
  return YES;
}


#pragma mark -
#pragma mark - Rotation
#pragma mark -

CGPoint LTRotatePoint(CGPoint point, CGFloat angle, CGPoint anchor) {
  point = point + (-1 * anchor);
  CGPoint result;
  result.x = std::cos(angle) * point.x - std::sin(angle) * point.y;
  result.y = std::sin(angle) * point.x + std::cos(angle) * point.y;
  return result + anchor;
}

#pragma mark -
#pragma mark - Intersection
#pragma mark -

// TODO:(Rouven) This method implements a naive O(n^2) approach. More efficient algorithms are
// possible and should be implemented if required. E.g. the Bentley Ottmann sweep line algorithm
// solves this problem in O(n log n).
BOOL LTIsSelfIntersectingPolyline(const CGPoints &points) {
  for (CGPoints::size_type i = 0; i + 1 < points.size(); ++i) {
    CGPoint p0 = points[i];
    CGPoint p1 = points[i + 1];
    for (CGPoints::size_type j = i + 1; j + 1 < points.size(); ++j) {
      CGPoint q0 = points[j];
      CGPoint q1 = points[j + 1];
      if (LTEdgesIntersect(p0, p1, q0, q1)) {
        return YES;
      }
    }
  }
  return NO;
}

// TODO:(Rouven) See comment about efficiency of LTIsSelfIntersectingPolyline.
CGPoints LTComputeIntersectionPointsOfPolyLine(const CGPoints &points) {
  CGPoints result;
  for (CGPoints::size_type i = 0; i + 1 < points.size(); ++i) {
    CGPoint p0 = points[i];
    CGPoint p1 = points[i + 1];
    for (CGPoints::size_type j = i + 1; j + 1 < points.size(); ++j) {
      CGPoint q0 = points[j];
      CGPoint q1 = points[j + 1];
      if (LTEdgesIntersect(p0, p1, q0, q1)) {
        result.push_back(LTIntersectionPointOfEdges(p0, p1, q0, q1));
      }
    }
  }
  return result;
}

/// @see http://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect
static CGPoint LTIntersectionPointOfLinesHelper(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1,
                                                CGFloat tMin = -CGFLOAT_MAX,
                                                CGFloat tMax = CGFLOAT_MAX) {
  CGPoint r = p1 - p0;
  CGPoint s = q1 - q0;
  CGFloat crossProductLength =
      GLKVector3Length(GLKVector3CrossProduct(GLKVector3Make(r.x, r.y, 0),
                                              GLKVector3Make(s.x, s.y, 0)));
  if (std::abs(crossProductLength) < kEpsilon) {
    // Line (segments) are parallel.
    return CGPointNull;
  }

  CGPoint qp = q0 - p0;
  CGFloat t = GLKVector3Length(GLKVector3CrossProduct(GLKVector3Make(qp.x, qp.y, 0),
                                                      GLKVector3Make(s.x, s.y, 0)));
  t /= crossProductLength;
  if (tMin <= t && t <= tMax) {
    // Note that the sign of \c t resulting from the previous cross product computation is
    // meaningless since there is no assumption on the geometric constellation of the vectors \c r
    // and \c s. Hence, it must be ensured that the sign of \c t is correct such that p0 + t * r
    // indeed is the intersection point (and not a point lying on line (p0, p1), but not (q0, q1).
    // The following distance-from-line computation has been chosen to provide a numerically robust,
    // correct answer. Simply checking collinearity of \c (q0, q1, intersectionPoint<x>), where
    // <x> in {0, 1} may yield wrong results. Another possibility would be to enforce an invariance
    // on the geometric constellation of vectors \c r and \c s. However, this might imply edge cases
    // to deal with.
    CGPoint intersectionPoint0 = p0 + t * r;
    CGPoint intersectionPoint1 = p0 + -t * r;
    CGFloat distance0 = LTDistanceFromLine(q0, q1, intersectionPoint0);
    CGFloat distance1 = LTDistanceFromLine(q0, q1, intersectionPoint1);
    if (distance0 < distance1) {
      return intersectionPoint0;
    }
    return intersectionPoint1;
  }
  return CGPointNull;
}

CGPoint LTIntersectionPointOfEdges(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1) {
  return LTIntersectionPointOfLinesHelper(p0, p1, q0, q1, 0, 1);
}

CGPoint LTIntersectionPointOfLines(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1) {
  return LTIntersectionPointOfLinesHelper(p0, p1, q0, q1);
}

BOOL LTEdgesIntersect(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1) {
  if (p0 == q0 || p0 == q1 || p1 == q0 || p1 == q1) {
    return NO;
  }
  return LTPointLocationRelativeToRay(q0, p0, p1 - p0)
      != LTPointLocationRelativeToRay(q1, p0, p1 - p0)
      && LTPointLocationRelativeToRay(p0, q0, q1 - q0)
      != LTPointLocationRelativeToRay(p1, q0, q1 - q0);
}

#pragma mark -
#pragma mark - Point to line/edge relation
#pragma mark -

/// @see: http://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
LTVector2 LTVectorFromPointToClosestPointOnLine(CGPoint point, CGPoint pointOnLine,
                                                CGPoint anotherPointOnLine) {
  LTParameterAssert(pointOnLine != anotherPointOnLine);
  LTVector2 a = LTVector2(pointOnLine);
  LTVector2 n = (LTVector2(anotherPointOnLine) - a).normalized();
  LTVector2 ap = a - LTVector2(point);
  return ap - ((ap).dot(n) * n);
}

CGPoint LTPointOnLineClosestToPoint(CGPoint pointOnLine, CGPoint anotherPointOnLine,
                                    CGPoint point) {
  return point + (CGPoint)LTVectorFromPointToClosestPointOnLine(point, pointOnLine,
                                                                anotherPointOnLine);
}

CGPoint LTPointOnEdgeClosestToPoint(CGPoint p0, CGPoint p1, CGPoint point) {
  LTParameterAssert(p0 != p1);
  CGPoint pointOnLine = LTPointOnLineClosestToPoint(p0, p1, point);
  CGFloat distanceP0P1 = LTVector2(p0 - p1).length();
  CGFloat distanceP0PointOnLine = LTVector2(p0 - pointOnLine).length();
  CGFloat distanceP1PointOnLine = LTVector2(p1 - pointOnLine).length();
  if (distanceP0PointOnLine <= distanceP0P1 && distanceP1PointOnLine <= distanceP0P1) {
    return pointOnLine;
  } else if (distanceP0PointOnLine <= distanceP0P1) {
    return p0;
  }
  return p1;
}

CGFloat LTDistanceFromLine(CGPoint pointOnLine, CGPoint anotherPointOnLine, CGPoint point) {
  return LTVectorFromPointToClosestPointOnLine(point, pointOnLine, anotherPointOnLine).length();
}
