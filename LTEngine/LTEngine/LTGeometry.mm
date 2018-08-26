// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTGeometry.h"

#import "LTGLKitExtensions.h"

static const CGFloat kEpsilon = 1e-6;

LTPointLocation LTPointLocationRelativeToRay(CGPoint point, CGPoint origin, CGPoint direction) {
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
#pragma mark Convex hull
#pragma mark -

/// Method used for comparison of points during convex hull computation
static bool LTConvexHullPointComparison(CGPoint p, CGPoint q) {
  return p.x < q.x || (p.x == q.x && p.y < q.y);
}

/// For implementation details, @see http://en.wikibooks.org/wiki/Algorithm_Implementation/Geometry/Convex_hull/Monotone_chain.
CGPoints LTConvexHull(const CGPoints &points) {
  NSUInteger n = points.size();
  CGPoints result(2 * n);
  CGPoints sortedPoints = points;
  std::sort(sortedPoints.begin(), sortedPoints.end(), LTConvexHullPointComparison);

  // Construct lower hull.
  NSUInteger k = 0;
  for (NSUInteger i = 0; i < n; ++i) {
    while (k >= 2 && LTPointLocationLeftOfRay !=
           LTPointLocationRelativeToRay(sortedPoints[i], result[k - 2],
                                        result[k - 1] - result[k - 2])) {
      --k;
    }
    if (k == 0 || result[k - 1] != sortedPoints[i]) {
      result[k] = sortedPoints[i];
      ++k;
    }
  }

  // Construct upper hull.
  NSUInteger t = k + 1;
  for (NSInteger i = n - 2; i >= 0; --i) {
    while (k >= t && LTPointLocationLeftOfRay !=
           LTPointLocationRelativeToRay(sortedPoints[i], result[k - 2],
                                        result[k - 1] - result[k - 2])) {
      --k;
    }
    if (result[k - 1] != sortedPoints[i]) {
      result[k] = sortedPoints[i];
      ++k;
    }
  }

  // Remove endpoint if it conindices with the start point.
  if (k > 1 && result[0] == result[k - 1]) {
    result.resize(k - 1);
  } else {
    result.resize(k);
  }
  return result;
}

#pragma mark -
#pragma mark Boundary
#pragma mark -

static CGPoints LTCGPointsFromCVPoints(const std::vector<cv::Point> &points) {
  CGPoints output(points.size());

  std::transform(points.begin(), points.end(), output.begin(), [](const cv::Point &point) {
    return CGPointMake(point.x, point.y);
  });

  return output;
}

static std::vector<std::vector<cv::Point>> LTContours(const cv::Mat &mat, int mode) {
  LTParameterAssert(mat.type() == CV_8UC1,
                    @"Type (%lu) of mat must be CV_8UC1", (unsigned long)mat.type());
  std::vector<std::vector<cv::Point>> contours;

  cv::Mat1b buffer = cv::Mat1b(mat.rows + 2, mat.cols + 2, 0.0);
  mat.copyTo(buffer(cv::Rect(1, 1, mat.cols, mat.rows)));

  cv::findContours(buffer, contours, mode, cv::CHAIN_APPROX_TC89_KCOS, cv::Point(-1, -1));
  return contours;
}

CGPoints LTOuterBoundary(const cv::Mat &mat) {
  std::vector<std::vector<cv::Point>> contours = LTContours(mat, cv::RETR_EXTERNAL);
  return !contours.size() ? CGPoints() : LTCGPointsFromCVPoints(contours[0]);
}

std::vector<CGPoints> LTBoundaries(const cv::Mat &mat) {
  std::vector<std::vector<cv::Point>> contours = LTContours(mat, cv::RETR_LIST);

  std::vector<CGPoints> boundaries;
  for(auto contour : contours) {
    boundaries.push_back(LTCGPointsFromCVPoints(contour));
  }
  return boundaries;
}

#pragma mark -
#pragma mark Rotation
#pragma mark -

CGPoint LTRotatePoint(CGPoint point, CGFloat angle, CGPoint anchor) {
  point = point + (-1 * anchor);
  CGPoint result;
  CGFloat sinAngle = std::sin(angle);
  CGFloat cosAngle = std::cos(angle);
  result.x = cosAngle * point.x - sinAngle * point.y;
  result.y = sinAngle * point.x + cosAngle * point.y;
  return result + anchor;
}

#pragma mark -
#pragma mark Intersection
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
      CGPoint intersectionPoint = LTIntersectionPointOfEdges(p0, p1, q0, q1);
      if (!CGPointIsNull(intersectionPoint)) {
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
      CGPoint intersectionPoint = LTIntersectionPointOfEdges(p0, p1, q0, q1);
      if (!CGPointIsNull(intersectionPoint)) {
        result.push_back(intersectionPoint);
      }
    }
  }
  return result;
}

// TODO:(Rouven) See comment about efficiency of LTIsSelfIntersectingPolyline.
CGPoints LTComputeIntersectionPointsOfPolyLines(const CGPoints &polyline0,
                                                const CGPoints &polyline1) {
  CGPoints result;
  for (CGPoints::size_type i = 0; i + 1 < polyline0.size(); ++i) {
    CGPoint p0 = polyline0[i];
    CGPoint p1 = polyline0[i + 1];
    for (CGPoints::size_type j = 0; j + 1 < polyline1.size(); ++j) {
      CGPoint q0 = polyline1[j];
      CGPoint q1 = polyline1[j + 1];
      CGPoint intersectionPoint = LTIntersectionPointOfEdges(p0, p1, q0, q1);
      if (!CGPointIsNull(intersectionPoint)) {
        result.push_back(intersectionPoint);
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
  CGFloat denominator =
      GLKVector3CrossProduct(GLKVector3Make(r.x, r.y, 0), GLKVector3Make(s.x, s.y, 0)).z;
  if (std::abs(denominator) < kEpsilon) {
    // Lines/segments are parallel.
    return CGPointNull;
  }

  CGPoint qp = q0 - p0;
  CGFloat t = GLKVector3CrossProduct(GLKVector3Make(qp.x, qp.y, 0), GLKVector3Make(s.x, s.y, 0)).z;
  t /= denominator;
  CGFloat u = GLKVector3CrossProduct(GLKVector3Make(qp.x, qp.y, 0), GLKVector3Make(r.x, r.y, 0)).z;
  u /= denominator;
  if (tMin <= t && t <= tMax && tMin <= u && u <= tMax) {
    return p0 + t * r;
  }
  return CGPointNull;
}

CGPoint LTIntersectionPointOfEdges(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1) {
  if (p0 == q0 || p0 == q1 || p1 == q0 || p1 == q1) {
    return CGPointNull;
  }
  return LTIntersectionPointOfLinesHelper(p0, p1, q0, q1, 0, 1);
}

CGPoint LTIntersectionPointOfEdgeAndLine(CGPoint edgePoint0, CGPoint edgePoint1,
                                         CGPoint lineOnPoint0, CGPoint lineOnPoint1) {
  CGPoint result = LTIntersectionPointOfLines(edgePoint0, edgePoint1, lineOnPoint0, lineOnPoint1);
  if (CGPointIsNull(result)) {
    return result;
  }

  CGFloat edgeLength = CGPointDistance(edgePoint0, edgePoint1);
  return (CGPointDistance(result, edgePoint0) <= edgeLength &&
          CGPointDistance(result, edgePoint1) <= edgeLength) ? result : CGPointNull;
}

CGPoint LTIntersectionPointOfLines(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1) {
  return LTIntersectionPointOfLinesHelper(p0, p1, q0, q1);
}

#pragma mark -
#pragma mark Point to line/edge relation
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

/// @see http://web.archive.org/web/20141117113118/http://geomalgorithms.com/a07-_distance.html for
/// more details.
CGPointPair LTPointOnEdgeNearestToPointOnEdge(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1) {
  CGPoint intersectionPoint = LTIntersectionPointOfEdges(p0, p1, q0, q1);
  if (!CGPointIsNull(intersectionPoint)) {
    return {intersectionPoint, intersectionPoint};
  }

  LTVector2 u = LTVector2(p1 - p0);
  LTVector2 v = LTVector2(q1 - q0);
  LTVector2 w = LTVector2(p0 - q0);
  CGFloat a = u.dot(u);
  CGFloat b = u.dot(v);
  CGFloat c = v.dot(v);
  CGFloat d = u.dot(w);
  CGFloat e = v.dot(w);
  CGFloat m = a * c - b * b;
  CGFloat s, s0, s1 = m;
  CGFloat t, t0, t1 = m;

  if (m < kEpsilon) {
    s0 = 0;
    s1 = 1;
    t0 = e;
    t1 = c;
  } else {
    s0 = (b * e - c * d);
    t0 = (a * e - b * d);

    if (s0 < 0) {
      s0 = 0;
      t0 = e;
      t1 = c;
    } else if (s0 > s1) {
      s0 = s1;
      t0 = e + b;
      t1 = c;
    }
  }

  if (t0 < 0) {
    t0 = 0;

    if (-d < 0) {
      s0 = 0;
    } else if (-d > a) {
      s0 = s1;
    } else {
      s0 = -d;
      s1 = a;
    }
  } else if (t0 > t1) {
    t0 = t1;

    if ((-d + b) < 0) {
      s0 = 0;
    } else if ((-d + b) > a) {
      s0 = s1;
    } else {
      s0 = (-d +  b);
      s1 = a;
    }
  }

  s = (std::abs(s0) < kEpsilon ? 0 : s0 / s1);
  t = (std::abs(t0) < kEpsilon ? 0 : t0 / t1);

  return {(p0 + (CGPoint)(s * u)), (q0 + (CGPoint)(t * v))};
}

CGPointPair LTPointOnPolylineNearestToPointOnPolyline(const CGPoints &polyline0,
                                                      const CGPoints &polyline1) {
  CGPointPair result;
  CGPoints intersectionPoints = LTComputeIntersectionPointsOfPolyLines(polyline0, polyline1);
  if (intersectionPoints.size()) {
    result.first = intersectionPoints[0];
    result.second = intersectionPoints[0];
    return result;
  }

  CGFloat minDistance = CGFLOAT_MAX;

  for (CGPoints::size_type i = 0; i + 1 < polyline0.size(); ++i) {
    CGPoint p0 = polyline0[i];
    CGPoint p1 = polyline0[i + 1];
    for (CGPoints::size_type j = 0; j + 1 < polyline1.size(); ++j) {
      CGPoint q0 = polyline1[j];
      CGPoint q1 = polyline1[j + 1];

      CGPointPair closestPoints = LTPointOnEdgeNearestToPointOnEdge(p0, p1, q0, q1);

      CGFloat distance = CGPointDistance(closestPoints.first, closestPoints.second);

      if (distance < minDistance) {
        result = closestPoints;
        minDistance = distance;
      }
    }
  }

  return result;
}

CGFloat LTDistanceFromLine(CGPoint pointOnLine, CGPoint anotherPointOnLine, CGPoint point) {
  return LTVectorFromPointToClosestPointOnLine(point, pointOnLine, anotherPointOnLine).length();
}

CGFloat LTDistanceFromEdge(CGPoint p0, CGPoint p1, CGPoint point) {
  return CGPointDistance(point, LTPointOnEdgeClosestToPoint(p0, p1, point));
}

CGPoint LTPointOnPolylineNearestToPoint(const CGPoints &polyline, CGPoint point) {
  LTParameterAssert(polyline.size() >= 2, @"Given polyline of invalid size: %lu",
                    (unsigned long)polyline.size());

  CGPoint result = CGPointNull;
  CGFloat minDistance = CGFLOAT_MAX;

  for(CGPoints::size_type i = 0; i + 1 < polyline.size(); ++i) {
    CGPoint p0 = polyline[i];
    CGPoint p1 = polyline[i + 1];

    CGPoint closestPoint = p0 != p1 ? LTPointOnEdgeClosestToPoint(p0, p1, point) : p0;
    CGFloat distance = CGPointDistance(closestPoint, point);

    if (distance < minDistance) {
      result = closestPoint;
      minDistance = distance;
    }
  }

  return result;
}

CGFloat LTDistanceFromPolyLine(const CGPoints &polyline, CGPoint point) {
  return CGPointDistance(LTPointOnPolylineNearestToPoint(polyline, point), point);
};
