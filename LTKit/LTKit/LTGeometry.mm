// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTGeometry.h"

#import "LTGLKitExtensions.h"

BOOL LTPointLiesOnRightSideOfRay(CGPoint p, CGPoint q, CGPoint r) {
  GLKMatrix3 matrix = GLKMatrix3Make(q.x, q.y, 1,
                                     r.x, r.y, 1,
                                     p.x, p.y, 1);
  if (GLKMatrix3Determinant(matrix) < 0) {
    return NO;
  }
  return YES;
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

BOOL LTEdgesIntersect(CGPoint p0, CGPoint p1, CGPoint q0, CGPoint q1) {
  if (p0 == q0 || p0 == q1 || p1 == q0 || p1 == q1) {
    return NO;
  }

  return LTPointLiesOnRightSideOfRay(q0, p0, p1) != LTPointLiesOnRightSideOfRay(q1, p0, p1)
      && LTPointLiesOnRightSideOfRay(p0, q0, q1) != LTPointLiesOnRightSideOfRay(p1, q0, q1);
}
