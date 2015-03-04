// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTGeometry.h"

#import "LTGLKitExtensions.h"
#import "LTRandom.h"

static CGFloat LTScalarProjection(CGPoint p, CGPoint q, CGPoint r) {
  return LTVector2(p - r).dot(LTVector2(q - r).normalized());
}

static CGPointPair LTPointOnEdgeNearestToPointOnEdgeTest(CGPoint p0, CGPoint p1,
                                                         CGPoint q0, CGPoint q1) {
  CGPointPair result;

  CGPoint p0p1Normalized = (CGPoint)(LTVector2(p1 - p0).normalized());
  CGPoint q0q1Normalized = (CGPoint)(LTVector2(q1 - q0).normalized());

  CGFloat p0p1Length = CGPointDistance(p0, p1);
  CGFloat q0q1Length = CGPointDistance(q0, q1);

  CGPoints pCandidates{p0, p1,
      p0 + std::clamp(LTScalarProjection(q0, p1, p0), 0, p0p1Length) * p0p1Normalized,
      p0 + std::clamp(LTScalarProjection(q1, p1, p0), 0, p0p1Length) * p0p1Normalized};
  CGPoints qCandidates{q0, q1,
    q0 + std::clamp(LTScalarProjection(p0, q1, q0), 0, q0q1Length) * q0q1Normalized,
    q0 + std::clamp(LTScalarProjection(p1, q1, q0), 0, q0q1Length) * q0q1Normalized};

  CGFloat minDistance = CGFLOAT_MAX;

  for (const CGPoint &p : pCandidates) {
    for (const CGPoint &q : qCandidates) {
      CGFloat distance = CGPointDistance(p, q);
      if (distance < minDistance) {
        minDistance = distance;
        result.first = p;
        result.second = q;
      }
    }
  }

  return result;
}

static NSInteger LTRandomSign(LTRandom *random) {
  return [random randomIntegerBetweenMin:0 max:1] ?: -1;
}

LTSpecBegin(LTGeometry)

static const CGFloat kEpsilon = 1e-6;
static const CGFloat kNumberOfEdgePointTests = 1000;
static const CGFloat kEdgePointTestsEpsilon = 1e-4;

context(@"relative point location in 2D", ^{
  it(@"should correctly compute the location of a point in relation to a ray", ^{
    const CGPoint p = CGPointMake(0.5, 1);
    const CGPoint q = CGPointZero;
    const CGPoint r = CGPointMake(1, 0);
    BOOL liesOnRightSide = LTPointLocationRelativeToRay(p, q, r - q) == LTPointLocationRightOfRay;
    expect(liesOnRightSide).to.beTruthy();
    BOOL liesOnLeftSide = LTPointLocationRelativeToRay(r, q, p - q) == LTPointLocationLeftOfRay;
    expect(liesOnLeftSide).to.beTruthy();
    BOOL liesOnLineThroughRay =
        LTPointLocationRelativeToRay(r, r, q - r) == LTPointLocationOnLineThroughRay;
    expect(liesOnLineThroughRay).to.beTruthy();
  });
});

context(@"collinearity", ^{
  it(@"should correctly compute whether points are collinear", ^{
    CGPoints points0{CGPointZero};
    expect(LTPointsAreCollinear(points0)).to.beTruthy();
    CGPoints points1{CGPointZero, CGPointZero};
    expect(LTPointsAreCollinear(points1)).to.beTruthy();
    CGPoints points2{CGPointZero, CGPointMake(1, 1)};
    expect(LTPointsAreCollinear(points2)).to.beTruthy();
    CGPoints points3{CGPointZero, CGPointMake(1, 1), CGPointMake(0.5, 0.5)};
    expect(LTPointsAreCollinear(points3)).to.beTruthy();
    CGPoints points4{CGPointMake(1, 1), CGPointMake(M_PI, M_PI), CGPointMake(M_PI_2, M_PI_2)};
    expect(LTPointsAreCollinear(points4)).to.beTruthy();
    CGPoints points5{CGPointMake(1, 1), CGPointMake(2, 2), CGPointMake(3, 2)};
    expect(LTPointsAreCollinear(points5)).to.beFalsy();
    CGPoints points6{CGPointMake(1, 1), CGPointMake(2, 2), CGPointMake(3, 3), CGPointMake(4, 4)};
    expect(LTPointsAreCollinear(points6)).to.beTruthy();
    CGPoints points7{CGPointMake(1, 1), CGPointMake(2, 2), CGPointMake(3, 3), CGPointMake(4, 4.5)};
    expect(LTPointsAreCollinear(points7)).to.beFalsy();
  });
});

context(@"affine transformations", ^{
  it(@"should correctly rotate a given point", ^{
    CGPoint point = LTRotatePoint(CGPointMake(1, 0), M_PI_2);
    expect(point).to.beCloseToPointWithin(CGPointMake(0, 1), kEpsilon);

    point = LTRotatePoint(CGPointMake(2.5, 1.56), 28.29 / 180.0 * M_PI);
    expect(point).to.beCloseToPointWithin(CGPointMake(1.46206236, 2.55851007), kEpsilon);
  });

  it(@"should correctly rotate a given point around a given point", ^{
    CGPoint point = LTRotatePoint(CGPointMake(1, 0), M_PI_2, CGPointZero);
    expect(point).to.beCloseToPointWithin(CGPointMake(0, 1), kEpsilon);

    point = LTRotatePoint(CGPointMake(2, 1), M_PI_2, CGPointMake(1, 1));
    expect(point).to.beCloseToPointWithin(CGPointMake(1, 2), kEpsilon);

    point = LTRotatePoint(CGPointMake(2.5, 1.56), 28.29 / 180.0 * M_PI, CGPointMake(6.7, -19.1));
    expect(point).to.beCloseToPointWithin(CGPointMake(-6.78983974, -2.89815331), kEpsilon);
  });
});

context(@"intersection", ^{
  it(@"should correctly compute whether two edges intersect", ^{
    CGPoint p0 = CGPointZero;
    CGPoint p1 = CGPointMake(1, 0);
    CGPoint q0 = CGPointMake(0.5, -0.5);
    CGPoint q1 = CGPointMake(0.5, 0.5);
    expect(LTEdgesIntersect(p0, p1, q0, q1)).to.beTruthy();
    expect(LTEdgesIntersect(p0, q0, p1, q1)).to.beFalsy();
    expect(LTEdgesIntersect(p0, q0, CGPointMake(2, -1), CGPointMake(2, 1))).to.beFalsy();
  });

  it(@"it should correctly compute whether a given polyline intersects itself", ^{
    CGPoint p0 = CGPointZero;
    CGPoint p1 = CGPointMake(1, 0);
    CGPoint p2 = CGPointMake(0.5, -0.5);
    CGPoint p3 = CGPointMake(0.5, 0.5);
    CGPoints pointsToCheck{p0, p1, p2, p3};
    expect(LTIsSelfIntersectingPolyline(pointsToCheck)).to.beTruthy();
    CGPoints pointsToCheck2{p0, p2, p3, p1};
    expect(LTIsSelfIntersectingPolyline(pointsToCheck2)).to.beFalsy();
  });

  context(@"intersection point of two edges", ^{
    __block CGPoint p0;
    __block CGPoint p1;
    __block CGPoint p2;
    __block CGPoint p3;

    beforeEach(^{
      p0 = CGPointZero;
      p1 = CGPointMake(1, 1);
      p2 = CGPointMake(0, -1);
      p3 = CGPointMake(1, 2);
    });

    context(@"overlapping edges", ^{
      it(@"should correctly compute the intersection point of two intersecting edges", ^{
        expect(LTIntersectionPointOfEdges(p0, p1, p2, p3))
            .to.beCloseToPointWithin(CGPointMake(0.5, 0.5), kEpsilon);

        p0 = CGPointZero;
        p1 = CGPointMake(1, 0);
        p2 = CGPointMake(0.5, -0.5);
        p3 = CGPointMake(0, 0.5);
        expect(LTIntersectionPointOfEdges(p0, p1, p2, p3))
            .to.beCloseToPointWithin(CGPointMake(0.25, 0), kEpsilon);
      });

      it(@"should return CGPointNull for collinear overlapping edges", ^{
        p2 = CGPointMake(0.5, 0.5);
        p3 = CGPointMake(2, 2);

        expect(CGPointIsNull(LTIntersectionPointOfEdges(p0, p1, p2, p3))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p1, p0, p2, p3))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p0, p1, p3, p2))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p1, p0, p3, p2))).to.beTruthy();
      });
    });

    context(@"disjoint edges", ^{
      it(@"should return CGPointNull for adjacent edges", ^{
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p0, p1, p1, p2))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p0, p2, p2, p1))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p1, p0, p0, p2))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p1, p2, p1, p0))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p2, p0, p0, p1))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p2, p1, p1, p0))).to.beTruthy();
      });

      it(@"should return CGPointNull for non-collinear but parallel edges", ^{
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p0, p2, p1, p3))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p2, p0, p1, p3))).to.beTruthy();
      });

      it(@"should return CGPointNull for non-overlapping but collinear edges", ^{
        p2 = CGPointMake(2, 2);
        p3 = CGPointMake(8, 8);

        expect(CGPointIsNull(LTIntersectionPointOfEdges(p0, p1, p2, p3))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p1, p0, p2, p3))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p0, p1, p3, p2))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p1, p0, p3, p2))).to.beTruthy();
      });

      it(@"should return CGPointNull for non-intersecting non-parallel edges", ^{
        p1 = CGPointMake(0, 1);
        p2 = CGPointMake(0.5, 0.5);
        p3 = CGPointMake(1, 0.5);
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p0, p1, p2, p3))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p1, p0, p2, p3))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p0, p1, p3, p2))).to.beTruthy();
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p1, p0, p3, p2))).to.beTruthy();

        p1 = CGPointMake(0, 1);
        p2 = CGPointMake(0.5, 0.5);
        p3 = CGPointMake(1, 0.6);
        expect(CGPointIsNull(LTIntersectionPointOfEdges(p0, p1, p2, p3))).to.beTruthy();
      });
    });
  });

  it(@"should correctly compute the intersection point of an edge and a line", ^{
    CGPoint p0 = CGPointZero;
    CGPoint p1 = CGPointMake(1, 0);
    CGPoint p2 = CGPointMake(0.5, -1.5);
    CGPoint p3 = CGPointMake(0.5, -0.5);
    expect(LTIntersectionPointOfEdgeAndLine(p0, p1, p2, p3)).to.
        beCloseToPointWithin(CGPointMake(0.5, 0), kEpsilon);
    expect(CGPointIsNull(LTIntersectionPointOfEdgeAndLine(p2, p3, p0, p1))).to.beTruthy();

    p2 = CGPointMake(0.5, -0.5);
    p3 = CGPointMake(0, 0.5);

    expect(LTIntersectionPointOfEdgeAndLine(p0, p1, p2, p3)).to.
        beCloseToPointWithin(CGPointMake(0.25, 0), kEpsilon);
  });

  it(@"should correctly compute the intersection point of two lines", ^{
    CGPoint p0 = CGPointZero;
    CGPoint p1 = CGPointMake(1, 0);
    CGPoint p2 = CGPointMake(0.5, -0.5);
    CGPoint p3 = CGPointMake(0, 0.5);
    expect(LTIntersectionPointOfLines(p0, p1, p2, p3)).to.beCloseToPointWithin(CGPointMake(0.25, 0),
                                                                               kEpsilon);
    expect(LTIntersectionPointOfLines(p0, p1, p1, p2)).to.beCloseToPointWithin(p1, kEpsilon);
    expect(LTIntersectionPointOfLines(p0, p2, p1, p3)).to.beCloseToPointWithin(CGPointMake(-1, 1),
                                                                               kEpsilon);
    expect(CGPointIsNull(LTIntersectionPointOfLines(p0, p2, p0, p2))).to.beTruthy();
    CGPoint shift = CGPointMake(0, 1);
    expect(CGPointIsNull(LTIntersectionPointOfLines(p0, p2, p0 + shift, p2 + shift))).to.beTruthy();
    CGPoint q0 = CGPointMake(0, 1);
    expect(CGPointIsNull(LTIntersectionPointOfLines(p0, q0, p0 + shift, q0 + shift))).to.beTruthy();
  });

  it(@"it should correctly compute all intersection points of a given polyline", ^{
    CGPoint p0 = CGPointZero;
    CGPoint p1 = CGPointMake(1, 0);
    CGPoint p2 = CGPointMake(0.5, -0.5);
    CGPoint p3 = CGPointMake(0, 0.5);
    CGPoint p4 = CGPointMake(1, -0.5);
    CGPoints pointsToCheck{p0, p1, p2, p3, p4};
    CGPoints expectedIntersectionPoints = LTComputeIntersectionPointsOfPolyLine(pointsToCheck);
    expect(expectedIntersectionPoints.size()).to.equal(3);
    expect(expectedIntersectionPoints[0]).to.beCloseToPointWithin(CGPointMake(0.25, 0), kEpsilon);
    expect(expectedIntersectionPoints[1]).to.beCloseToPointWithin(CGPointMake(0.5, 0), kEpsilon);
    expect(expectedIntersectionPoints[2]).to.beCloseToPointWithin(CGPointMake(0.75, -0.25),
                                                                  kEpsilon);
  });

  it(@"it should correctly compute all intersection points of two given polylines", ^{
    CGPoints polyline0{CGPointZero, CGPointMake(1, 0), CGPointMake(1, 1),
        CGPointMake(2, 1), CGPointMake(1, 2)};
    CGPoints polyline1{CGPointMake(0.5, -0.5), CGPointMake(0.5, 0.5), CGPointMake(1.5, 0.5),
        CGPointMake(1.5, 2)};
    CGPoints intersectionPoints = LTComputeIntersectionPointsOfPolyLines(polyline0, polyline1);
    expect(intersectionPoints.size()).to.equal(4);
    expect(intersectionPoints[0]).to.beCloseToPointWithin(CGPointMake(0.5, 0), kEpsilon);
    expect(intersectionPoints[1]).to.beCloseToPointWithin(CGPointMake(1, 0.5), kEpsilon);
    expect(intersectionPoints[2]).to.beCloseToPointWithin(CGPointMake(1.5, 1), kEpsilon);
    expect(intersectionPoints[3]).to.beCloseToPointWithin(CGPointMake(1.5, 1.5), kEpsilon);
  });
});

context(@"relationship point and line/edge", ^{
  it(@"should correctly compute the closest point on a line from a given point", ^{
    CGPoint a = CGPointZero;
    CGPoint b = CGPointMake(1, 0);
    CGPoint point = CGPointMake(0.5, 0.5);
    expect(LTPointOnLineClosestToPoint(a, b, point)).to.beCloseToPointWithin(CGPointMake(0.5, 0),
                                                                             kEpsilon);

    a = CGPointZero;
    b = CGPointMake(1, 1);
    point = CGPointMake(0.5, 0.5);
    expect(LTPointOnLineClosestToPoint(a, b, point)).to.beCloseToPointWithin(CGPointMake(0.5, 0.5),
                                                                             kEpsilon);

    a = CGPointZero;
    b = CGPointMake(0, 1);
    point = CGPointMake(2, 0);
    expect(LTPointOnLineClosestToPoint(a, b, point)).to.beCloseToPointWithin(CGPointZero, kEpsilon);
  });

  it(@"should correctly compute the closest point on an edge from a given point", ^{
    CGPoint a = CGPointZero;
    CGPoint b = CGPointMake(1, 0);
    CGPoint point = CGPointMake(0.5, 0.5);
    expect(LTPointOnEdgeClosestToPoint(a, b, point)).to.beCloseToPointWithin(CGPointMake(0.5, 0),
                                                                             kEpsilon);

    a = CGPointZero;
    b = CGPointMake(1, 1);
    point = CGPointMake(1.5, 0.5);
    expect(LTPointOnEdgeClosestToPoint(a, b, point)).to.beCloseToPointWithin(CGPointMake(1, 1),
                                                                             kEpsilon);

    a = CGPointZero;
    b = CGPointMake(0, 1);
    point = CGPointMake(-2, -1);
    expect(LTPointOnEdgeClosestToPoint(a, b, point)).to.beCloseToPointWithin(CGPointZero, kEpsilon);
  });

  it(@"should correctly compute the two closest points on two given edges", ^{
    CGPoint p0 = CGPointZero;
    CGPoint p1 = CGPointMake(1, 0);
    CGPoint q0 = CGPointMake(0, 1);
    CGPoint q1 = CGPointMake(1, 1);
    CGPointPair result = LTPointOnEdgeNearestToPointOnEdge(p0, p1, q0, q1);
    CGPointPair expectedResult = LTPointOnEdgeNearestToPointOnEdgeTest(p0, p1, q0, q1);
    expect(result.first).to.beCloseToPointWithin(expectedResult.first, kEpsilon);
    expect(result.second).to.beCloseToPointWithin(expectedResult.second, kEpsilon);
    expect(result.first).to.beCloseToPointWithin(p0, kEpsilon);
    expect(result.second).to.beCloseToPointWithin(q0, kEpsilon);

    q0 = CGPointMake(2, -1);
    q1 = CGPointMake(2, 1);
    result = LTPointOnEdgeNearestToPointOnEdge(p0, p1, q0, q1);
    expectedResult = LTPointOnEdgeNearestToPointOnEdgeTest(p0, p1, q0, q1);
    expect(result.first).to.beCloseToPointWithin(expectedResult.first, kEpsilon);
    expect(result.second).to.beCloseToPointWithin(expectedResult.second, kEpsilon);
    expect(result.first).to.beCloseToPointWithin(p1, kEpsilon);
    expect(result.second).to.beCloseToPointWithin(CGPointMake(2, 0), kEpsilon);

    q0 = p0;
    q1 = p1;
    result = LTPointOnEdgeNearestToPointOnEdge(p0, p1, q0, q1);
    expectedResult = LTPointOnEdgeNearestToPointOnEdgeTest(p0, p1, q0, q1);
    expect(result.first).to.beCloseToPointWithin(expectedResult.first, kEpsilon);
    expect(result.second).to.beCloseToPointWithin(expectedResult.second, kEpsilon);
    expect(result.first).to.beCloseToPointWithin(p0, kEpsilon);
    expect(result.second).to.beCloseToPointWithin(q0, kEpsilon);

    q0 = CGPointMake(0.5, -1);
    q1 = CGPointMake(0.5, 1);
    result = LTPointOnEdgeNearestToPointOnEdge(p0, p1, q0, q1);
    expectedResult = LTPointOnEdgeNearestToPointOnEdgeTest(p0, p1, q0, q1);
    expect(result.first).to.beCloseToPointWithin(expectedResult.first, kEpsilon);
    expect(result.second).to.beCloseToPointWithin(expectedResult.second, kEpsilon);
    expect(result.first).to.beCloseToPointWithin(CGPointMake(0.5, 0), kEpsilon);
    expect(result.second).to.beCloseToPointWithin(CGPointMake(0.5, 0), kEpsilon);

    q0 = CGPointMake(0.5, 1);
    q1 = CGPointMake(2, 2);
    result = LTPointOnEdgeNearestToPointOnEdge(p0, p1, q0, q1);
    expectedResult = LTPointOnEdgeNearestToPointOnEdgeTest(p0, p1, q0, q1);
    expect(result.first).to.beCloseToPointWithin(expectedResult.first, kEpsilon);
    expect(result.second).to.beCloseToPointWithin(expectedResult.second, kEpsilon);
    expect(result.first).to.beCloseToPointWithin(CGPointMake(0.5, 0), kEpsilon);
    expect(result.second).to.beCloseToPointWithin(q0, kEpsilon);

    q0 = CGPointMake(0.5, 1);
    q1 = CGPointMake(2, 2);
    result = LTPointOnEdgeNearestToPointOnEdge(p0, p1, q0, q1);
    expectedResult = LTPointOnEdgeNearestToPointOnEdgeTest(p0, p1, q0, q1);
    expect(result.first).to.beCloseToPointWithin(expectedResult.first, kEpsilon);
    expect(result.second).to.beCloseToPointWithin(expectedResult.second, kEpsilon);
    expect(result.first).to.beCloseToPointWithin(CGPointMake(0.5, 0), kEpsilon);
    expect(result.second).to.beCloseToPointWithin(q0, kEpsilon);

    q0 = CGPointMake(0.8, 1);
    q1 = CGPointMake(0.4, 0.2);
    result = LTPointOnEdgeNearestToPointOnEdge(p0, p1, q0, q1);
    expectedResult = LTPointOnEdgeNearestToPointOnEdgeTest(p0, p1, q0, q1);
    expect(result.first).to.beCloseToPointWithin(expectedResult.first, kEpsilon);
    expect(result.second).to.beCloseToPointWithin(expectedResult.second, kEpsilon);
    expect(result.first).to.beCloseToPointWithin(CGPointMake(0.4, 0), kEpsilon);
    expect(result.second).to.beCloseToPointWithin(q1, kEpsilon);

    p0 = CGPointZero;
    p1 = CGPointMake(1, 1);
    q0 = CGPointMake(1, 0);
    q1 = CGPointMake(2, -1);
    result = LTPointOnEdgeNearestToPointOnEdge(p0, p1, q0, q1);
    expectedResult = LTPointOnEdgeNearestToPointOnEdgeTest(p0, p1, q0, q1);
    expect(result.first).to.beCloseToPointWithin(expectedResult.first, kEpsilon);
    expect(result.second).to.beCloseToPointWithin(expectedResult.second, kEpsilon);
    expect(result.first).to.beCloseToPointWithin(CGPointMake(0.5, 0.5), kEpsilon);
    expect(result.second).to.beCloseToPointWithin(q0, kEpsilon);

    LTRandom *random = [JSObjection defaultInjector][[LTRandom class]];

    for (NSUInteger i = 0; i < kNumberOfEdgePointTests; i++) {
      p0 = CGPointMake([random randomDoubleBetweenMin:-1e5 max:1e5],
                       [random randomDoubleBetweenMin:-1e5 max:1e5]);

      CGFloat distance = [random randomDoubleBetweenMin:0.1 max:1e5];
      CGFloat a = [random randomDoubleBetweenMin:0 max:1];
      CGFloat b = std::sqrt(1 - a * a);

      p1 = p0 + CGPointMake(LTRandomSign(random) * a * distance,
                            LTRandomSign(random) * b * distance);

      q0 = p0 + CGPointMake([random randomDoubleBetweenMin:100 * -distance max:100 * distance],
                            [random randomDoubleBetweenMin:100 * -distance max:100 * distance]);

      distance = [random randomDoubleBetweenMin:0.01 * distance max:100 * distance];
      a = [random randomDoubleBetweenMin:0 max:1];
      b = std::sqrt(1 - a * a);

      q1 = q0 + CGPointMake(LTRandomSign(random) * a * distance,
                            LTRandomSign(random) * b * distance);

      result = LTPointOnEdgeNearestToPointOnEdge(p0, p1, q0, q1);
      expectedResult = LTPointOnEdgeNearestToPointOnEdgeTest(p0, p1, q0, q1);
      CGFloat expectedDistance = CGPointDistance(expectedResult.first, expectedResult.second);
      expect(result.first).to.beCloseToPointWithin(expectedResult.first,
                                                   expectedDistance * kEdgePointTestsEpsilon);
      expect(result.second).to.beCloseToPointWithin(expectedResult.second,
                                                    expectedDistance * kEdgePointTestsEpsilon);
    }
  });

  it(@"should correctly compute the two closest points on two given polylines", ^{
    CGPoints polyline0{CGPointZero, CGPointMake(1, 0), CGPointMake(1, 1),
        CGPointMake(2, 1), CGPointMake(1, 2)};
    CGPoints polyline1{CGPointMake(0.5, -0.5), CGPointMake(0.5, 0.5), CGPointMake(1.5, 0.5),
        CGPointMake(1.5, 2)};
    CGPointPair result = LTPointOnPolylineNearestToPointOnPolyline(polyline0, polyline1);
    expect(result.first).to.equal(CGPointMake(0.5, 0));
    expect(result.second).to.equal(CGPointMake(0.5, 0));

    polyline0 = CGPoints{CGPointMake(-0.5, -0.5), CGPointZero, CGPointMake(1, 0),
        CGPointMake(1.5, -0.5)};
    polyline1 = CGPoints{CGPointMake(0, 2), CGPointMake(0.5, 1), CGPointMake(1, 2)};
    result = LTPointOnPolylineNearestToPointOnPolyline(polyline0, polyline1);
    expect(result.first).to.equal(CGPointMake(0.5, 0));
    expect(result.second).to.equal(CGPointMake(0.5, 1));
  });

  context(@"distance", ^{
    context(@"distance of point from line", ^{
      it(@"should correctly compute the distance of a point ON a line", ^{
        CGPoint a = CGPointZero;
        CGPoint b = CGPointMake(1, 1);
        CGPoint point = CGPointMake(0.5, 0.5);
        expect(LTDistanceFromLine(a, b, point)).to.beCloseToWithin(0, kEpsilon);
        a = CGPointMake(6, 5);
        b = CGPointMake(2, 5);
        point = CGPointMake(-10, 5);
        expect(LTDistanceFromLine(a, b, point)).to.beCloseToWithin(0, kEpsilon);
        a = CGPointMake(5, -2);
        b = CGPointMake(6, -1);
        point = CGPointMake(8, 1);
        expect(LTDistanceFromLine(a, b, point)).to.beCloseToWithin(0, kEpsilon);
      });

      it(@"should correctly compute the distance of a general point from a line", ^{
        CGPoint a = CGPointZero;
        CGPoint b = CGPointMake(1, 1);
        CGPoint point = CGPointMake(1, 0);
        expect(LTDistanceFromLine(a, b, point)).to.beCloseToWithin(M_SQRT1_2, kEpsilon);
        a = CGPointMake(6, 5);
        b = CGPointMake(2, 5);
        point = CGPointMake(-29, 3);
        expect(LTDistanceFromLine(a, b, point)).to.beCloseToWithin(2, kEpsilon);
        a = CGPointMake(5, -2);
        b = CGPointMake(5, -1);
        point = CGPointMake(8.5, 0);
        expect(LTDistanceFromLine(a, b, point)).to.beCloseToWithin(3.5, kEpsilon);
      });
    });

    context(@"distance of point from edge", ^{
      it(@"should correctly compute the distance of a point ON an edge", ^{
        CGPoint a = CGPointZero;
        CGPoint b = CGPointMake(1, 1);
        CGPoint point = CGPointMake(0.5, 0.5);
        expect(LTDistanceFromEdge(a, b, point)).to.beCloseToWithin(0, kEpsilon);
        a = CGPointMake(6, 5);
        b = CGPointMake(2, 5);
        point = CGPointMake(4, 5);
        expect(LTDistanceFromEdge(a, b, point)).to.beCloseToWithin(0, kEpsilon);
        point = a;
        expect(LTDistanceFromEdge(a, b, point)).to.beCloseToWithin(0, kEpsilon);
        point = b;
        expect(LTDistanceFromEdge(a, b, point)).to.beCloseToWithin(0, kEpsilon);
      });

      it(@"should correctly compute the distance of a general point from an edge", ^{
        CGPoint a = CGPointZero;
        CGPoint b = CGPointMake(1, 1);
        CGPoint point = CGPointMake(1, 0);
        expect(LTDistanceFromEdge(a, b, point)).to.beCloseToWithin(M_SQRT1_2, kEpsilon);
        a = CGPointMake(6, 5);
        b = CGPointMake(2, 5);
        point = CGPointMake(-10, 5);
        expect(LTDistanceFromEdge(a, b, point)).to.beCloseToWithin(12, kEpsilon);
        a = CGPointMake(5, -2);
        b = CGPointMake(6, -1);
        point = CGPointMake(8, 1);
        expect(LTDistanceFromEdge(a, b, point)).to.beCloseToWithin(2 * M_SQRT2, kEpsilon);
        a = CGPointMake(6, 5);
        b = CGPointMake(2, 5);
        point = CGPointMake(-29, 3);
        expect(LTDistanceFromEdge(a, b, point)).to.beCloseToWithin(31.06444913401813, kEpsilon);
        a = CGPointMake(5, -2);
        b = CGPointMake(5, -1);
        point = CGPointMake(8.5, 0);
        expect(LTDistanceFromEdge(a, b, point)).to.beCloseToWithin(3.640054944640259, kEpsilon);
      });
    });
  });
});

LTSpecEnd
