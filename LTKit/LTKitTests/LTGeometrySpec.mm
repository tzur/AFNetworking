// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTGeometry.h"

#import "LTGLKitExtensions.h"

SpecBegin(LTGeometry)

static const CGFloat kEpsilon = 1e-6;

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

  it(@"should correctly compute the intersection point of two edges", ^{
    CGPoint p0 = CGPointZero;
    CGPoint p1 = CGPointMake(1, 0);
    CGPoint p2 = CGPointMake(0.5, -0.5);
    CGPoint p3 = CGPointMake(0, 0.5);
    expect(LTIntersectionPointOfEdges(p0, p1, p2, p3)).to.beCloseToPointWithin(CGPointMake(0.25, 0),
                                                                               kEpsilon);
    expect(LTIntersectionPointOfEdges(p0, p1, p1, p2)).to.beCloseToPointWithin(p1, kEpsilon);
    expect(CGPointIsNull(LTIntersectionPointOfEdges(p0, p2, p1, p3))).to.beTruthy();
    expect(CGPointIsNull(LTIntersectionPointOfLines(p0, p2, p0, p2))).to.beTruthy();
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

SpecEnd
