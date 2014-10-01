// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTGeometry.h"

SpecBegin(LTGeometry)

context(@"relative point location in 2D", ^{
  it(@"should correctly compute the location of a point in relation to a ray", ^{
    const CGPoint p = CGPointMake(0.5, 1);
    const CGPoint q = CGPointMake(0, 0);
    const CGPoint r = CGPointMake(1, 0);
    BOOL liesOnRightSide = LTPointLiesOnRightSideOfRay(p, q, r);
    expect(liesOnRightSide).to.beTruthy();
    liesOnRightSide = LTPointLiesOnRightSideOfRay(r, q, p);
    expect(liesOnRightSide).to.beFalsy();
  });

  it(@"should correctly compute whether two edges intersect", ^{
    CGPoint p0 = CGPointMake(0, 0);
    CGPoint p1 = CGPointMake(1, 0);
    CGPoint q0 = CGPointMake(0.5, -0.5);
    CGPoint q1 = CGPointMake(0.5, 0.5);
    expect(LTEdgesIntersect(p0, p1, q0, q1)).to.beTruthy();
    expect(LTEdgesIntersect(p0, q0, p1, q1)).to.beFalsy();
    expect(LTEdgesIntersect(p0, q0, CGPointMake(2, -1), CGPointMake(2, 1))).to.beFalsy();
  });

  it(@"it should correctly compute whether a given polyline intersects itself", ^{
    CGPoint p0 = CGPointMake(0, 0);
    CGPoint p1 = CGPointMake(1, 0);
    CGPoint p2 = CGPointMake(0.5, -0.5);
    CGPoint p3 = CGPointMake(0.5, 0.5);
    CGPoints pointsToCheck{p0, p1, p2, p3};
    expect(LTIsSelfIntersectingPolyline(pointsToCheck)).to.beTruthy();
    CGPoints pointsToCheck2{p0, p2, p3, p1};
    expect(LTIsSelfIntersectingPolyline(pointsToCheck2)).to.beFalsy();
  });
});

SpecEnd
