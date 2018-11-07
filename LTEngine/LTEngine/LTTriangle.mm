// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTriangle.h"

#import "LTGeometry.h"

static BOOL LTCornersOfNullTriangle(const LTTriangleCorners &corners) {
  for (CGPoint corner : corners) {
    if (CGPointIsNull(corner)) {
      return YES;
    }
  }
  return NO;
}

static BOOL LTCornersOfPointTriangle(const LTTriangleCorners &corners) {
  CGPoint firstCorner = corners.front();

  for (CGPoint corner : corners) {
    if (corner != firstCorner) {
      return NO;
    }
  }
  return YES;
}

static lt::Triangle::Type LTTypeForCorners(const LTTriangleCorners &corners) {
  if (LTCornersOfNullTriangle(corners)) {
    return lt::Triangle::Type::Null;
  }

  if (LTCornersOfPointTriangle(corners)) {
    return lt::Triangle::Type::Point;
  }

  if (LTPointsAreCollinear({corners[0], corners[1], corners[2]})) {
    return lt::Triangle::Type::Collinear;
  }

  CGPoint direction = corners[1] - corners[0];
  BOOL clockwise = LTPointLocationRelativeToRay(corners[2], corners[0], direction) ==
      LTPointLocationRightOfRay;
  return clockwise ? lt::Triangle::Type::Clockwise : lt::Triangle::Type::CounterClockwise;
}

static LTTriangleCorners LTUpdatedCornersForType(const LTTriangleCorners &corners,
                                                 lt::Triangle::Type type) {
  if (type == lt::Triangle::Type::Null) {
    return {{CGPointNull, CGPointNull, CGPointNull}};
  }
  return corners;
}

namespace lt {

#pragma mark -
#pragma mark Initialization
#pragma mark -

Triangle::Triangle(const LTTriangleCorners &corners) noexcept {
  _triangleType = LTTypeForCorners(corners);
  _v = LTUpdatedCornersForType(corners, _triangleType);
}

#pragma mark -
#pragma mark Point containment/relation
#pragma mark -

BOOL LTNonDegenerateTriangleContainsPoint(CGPoint point, const LTTriangleCorners &corners,
                                          BOOL clockwise) {
  LTPointLocation location = clockwise ? LTPointLocationLeftOfRay : LTPointLocationRightOfRay;

  NSUInteger size = corners.size();
  for (NSUInteger i = 0; i < size; ++i) {
    CGPoint origin = corners[i];
    CGPoint direction = corners[(i + 1) % size] - origin;
    if (LTPointLocationRelativeToRay(point, origin, direction) == location) {
      return NO;
    }
  }
  return YES;
}

static const CGFloat kEpsilon = 1e-6;

BOOL Triangle::containsPoint(CGPoint point) const noexcept {
  switch (_triangleType) {
    case Triangle::Type::Null:
      return NO;
    case Triangle::Type::Point:
      return point == _v[0];
    case Triangle::Type::Collinear: {
      std::vector<CGPoint> points{_v[0], _v[1], _v[2]};
      std::vector<CGPoint> convexHull = LTConvexHull(points);
      return LTDistanceFromEdge(convexHull.front(), convexHull.back(), point) < kEpsilon;
    }
    case Triangle::Type::Clockwise:
      return LTNonDegenerateTriangleContainsPoint(point, _v, YES);
    case Triangle::Type::CounterClockwise:
      return LTNonDegenerateTriangleContainsPoint(point, _v, NO);
  }
}

} // namespace lt
