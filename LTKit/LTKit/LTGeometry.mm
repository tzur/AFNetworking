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

CGPoint LTRotatePoint(CGPoint point, CGFloat angle, CGPoint anchor) {
  point = point + (-1 * anchor);
  CGPoint result;
  result.x = std::cos(angle) * point.x - std::sin(angle) * point.y;
  result.y = std::sin(angle) * point.x + std::cos(angle) * point.y;
  return result + anchor;
}

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
CGPoint LTIntersectionPointOfEdges(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1) {
  CGSize r = p1 - p0;
  CGSize s = q1 - q0;
  CGFloat crossProductLength =
      GLKVector3Length(GLKVector3CrossProduct(GLKVector3Make(r.width, r.height, 0),
                                              GLKVector3Make(s.width, s.height, 0)));
  if (std::abs(crossProductLength) < kEpsilon) {
    return CGPointNull;
  }

  CGSize qp = q0 - p0;
  CGFloat t = GLKVector3Length(GLKVector3CrossProduct(GLKVector3Make(qp.width, qp.height, 0),
                                                      GLKVector3Make(s.width, s.height, 0)));
  t /= crossProductLength;
  if (0 <= t && t <= 1) {
    return p0 + t * r;
  }
  return CGPointNull;
}

BOOL LTEdgesIntersect(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1) {
  if (p0 == q0 || p0 == q1 || p1 == q0 || p1 == q1) {
    return NO;
  }

  return LTPointLocationRelativeToRay(q0, p0, CGPointFromSize(p1 - p0))
      != LTPointLocationRelativeToRay(q1, p0, CGPointFromSize(p1 - p0))
      && LTPointLocationRelativeToRay(p0, q0, CGPointFromSize(q1 - q0))
      != LTPointLocationRelativeToRay(p1, q0, CGPointFromSize(q1 - q0));
}
