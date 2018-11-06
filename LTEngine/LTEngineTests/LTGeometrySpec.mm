// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTGeometry.h"

#import <LTKit/LTRandom.h>

#import "LTGLKitExtensions.h"

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

  std::vector<CGPoint> pCandidates{p0, p1,
    p0 + std::clamp(LTScalarProjection(q0, p1, p0), 0., p0p1Length) * p0p1Normalized,
    p0 + std::clamp(LTScalarProjection(q1, p1, p0), 0., p0p1Length) * p0p1Normalized};
  std::vector<CGPoint> qCandidates{q0, q1,
    q0 + std::clamp(LTScalarProjection(p0, q1, q0), 0., q0q1Length) * q0q1Normalized,
    q0 + std::clamp(LTScalarProjection(p1, q1, q0), 0., q0q1Length) * q0q1Normalized};

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

SpecBegin(LTGeometry)

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
    std::vector<CGPoint> points0{CGPointZero};
    expect(LTPointsAreCollinear(points0)).to.beTruthy();
    std::vector<CGPoint> points1{CGPointZero, CGPointZero};
    expect(LTPointsAreCollinear(points1)).to.beTruthy();
    std::vector<CGPoint> points2{CGPointZero, CGPointMake(1, 1)};
    expect(LTPointsAreCollinear(points2)).to.beTruthy();
    std::vector<CGPoint> points3{CGPointZero, CGPointMake(1, 1), CGPointMake(0.5, 0.5)};
    expect(LTPointsAreCollinear(points3)).to.beTruthy();
    std::vector<CGPoint> points4{CGPointMake(1, 1), CGPointMake(M_PI, M_PI),
        CGPointMake(M_PI_2, M_PI_2)};
    expect(LTPointsAreCollinear(points4)).to.beTruthy();
    std::vector<CGPoint> points5{CGPointMake(1, 1), CGPointMake(2, 2), CGPointMake(3, 2)};
    expect(LTPointsAreCollinear(points5)).to.beFalsy();
    std::vector<CGPoint> points6{CGPointMake(1, 1), CGPointMake(2, 2), CGPointMake(3, 3),
        CGPointMake(4, 4)};
    expect(LTPointsAreCollinear(points6)).to.beTruthy();
    std::vector<CGPoint> points7{CGPointMake(1, 1), CGPointMake(2, 2), CGPointMake(3, 3),
        CGPointMake(4, 4.5)};
    expect(LTPointsAreCollinear(points7)).to.beFalsy();
  });
});

context(@"convex hull", ^{
  it(@"should correctly compute the convex hull of an empty set of points", ^{
    std::vector<CGPoint> convexHull = LTConvexHull({});
    expect(convexHull.size()).to.equal(0);
  });

  it(@"should correctly compute the convex hull of a set of points consisting of a single point", ^{
    std::vector<CGPoint> convexHull = LTConvexHull({CGPointMake(1, 2)});
    expect(convexHull.size()).to.equal(1);
    expect(convexHull[0]).to.equal(CGPointMake(1, 2));
  });

  context(@"two points", ^{
    it(@"should correctly compute the convex hull of a set of two points", ^{
      std::vector<CGPoint> convexHull = LTConvexHull({CGPointMake(2, 3), CGPointMake(1, 2)});
      expect(convexHull.size()).to.equal(2);
      expect(convexHull[0]).to.equal(CGPointMake(1, 2));
      expect(convexHull[1]).to.equal(CGPointMake(2, 3));
    });

    it(@"should correctly compute the convex hull of a set of two identical points", ^{
      std::vector<CGPoint> convexHull = LTConvexHull({CGPointMake(1, 2), CGPointMake(1, 2)});
      expect(convexHull.size()).to.equal(1);
      expect(convexHull[0]).to.equal(CGPointMake(1, 2));
    });
  });

  context(@"three points", ^{
    it(@"should correctly compute the convex hull of a set of three non-collinear points", ^{
      std::vector<CGPoint> convexHull =
          LTConvexHull({CGPointMake(2, 3), CGPointMake(1, 1), CGPointMake(0, 1)});
      expect(convexHull.size()).to.equal(3);
      expect(convexHull[0]).to.equal(CGPointMake(0, 1));
      expect(convexHull[1]).to.equal(CGPointMake(2, 3));
      expect(convexHull[2]).to.equal(CGPointMake(1, 1));
    });

    it(@"should correctly compute the convex hull of a set of three collinear points", ^{
      std::vector<CGPoint> convexHull =
          LTConvexHull({CGPointMake(2, 3), CGPointMake(1, 2), CGPointMake(0, 1)});
      expect(convexHull.size()).to.equal(2);
      expect(convexHull[0]).to.equal(CGPointMake(0, 1));
      expect(convexHull[1]).to.equal(CGPointMake(2, 3));
    });
  });

  context(@"four points", ^{
    it(@"should correctly compute the convex hull of a set of four non-collinear points", ^{
      std::vector<CGPoint> convexHull =
          LTConvexHull({CGPointMake(2, 3), CGPointMake(1, 1), CGPointMake(0.5, 7),
        CGPointMake(0, 1)});
      expect(convexHull.size()).to.equal(4);
      expect(convexHull[0]).to.equal(CGPointMake(0, 1));
      expect(convexHull[1]).to.equal(CGPointMake(0.5, 7));
      expect(convexHull[2]).to.equal(CGPointMake(2, 3));
      expect(convexHull[3]).to.equal(CGPointMake(1, 1));
    });

    it(@"should correctly compute the convex hull of a set of four partially collinear points", ^{
      std::vector<CGPoint> convexHull =
          LTConvexHull({CGPointMake(2, 3), CGPointMake(1, 2), CGPointMake(0.5, 7),
        CGPointMake(0, 1)});
      expect(convexHull.size()).to.equal(3);
      expect(convexHull[0]).to.equal(CGPointMake(0, 1));
      expect(convexHull[1]).to.equal(CGPointMake(0.5, 7));
      expect(convexHull[2]).to.equal(CGPointMake(2, 3));
    });

    it(@"should correctly compute the convex hull of a set of four collinear points", ^{
      std::vector<CGPoint> convexHull =
          LTConvexHull({CGPointMake(2, 3), CGPointMake(1, 2), CGPointMake(3, 4),
        CGPointMake(0, 1)});
      expect(convexHull.size()).to.equal(2);
      expect(convexHull[0]).to.equal(CGPointMake(0, 1));
      expect(convexHull[1]).to.equal(CGPointMake(3, 4));
    });
  });

  context(@"arbitary number of points", ^{
    it(@"should correctly compute the convex hull of a set of points", ^{
      LTRandom *random = [JSObjection defaultInjector][[LTRandom class]];

      std::vector<CGPoint> points;
      NSUInteger size = 1000;

      for (NSUInteger i = 0; i < size; ++i) {
        points.push_back(CGPointMake([random randomDoubleBetweenMin:0 max:1],
                                     [random randomDoubleBetweenMin:0 max:1]));
      }

      std::vector<CGPoint> convexHull = LTConvexHull(points);
      NSUInteger n = convexHull.size();
      expect(n).to.beGreaterThan(0);

      // Check that resulting points constitute a convex polygon.
      for (NSUInteger i = 0; i < n; ++i) {
        expect(LTPointLocationRelativeToRay(convexHull[(i + 2) % n], convexHull[i],
                                            convexHull[(i + 1) % n] - convexHull[i]))
            .toNot.equal(LTPointLocationRightOfRay);
      }

      // Check that all points lie inside the polygon.
      for (const CGPoint &p : points) {
        for (NSUInteger j = 0; j < n; ++j) {
          expect(LTPointLocationRelativeToRay(p, convexHull[j],
                                              convexHull[(j + 1) % n] - convexHull[j]))
              .toNot.equal(LTPointLocationRightOfRay);
        }
      }
    });
  });
});

context(@"outer boundary calculation", ^{
  it(@"should return no points on an empty mask", ^{
    cv::Mat1b mask = cv::Mat1b(3, 3, 0.0);
    std::vector<CGPoint> points = LTOuterBoundary(mask);
    expect(points.size()).to.equal(0);
  });

  it(@"should return the correct points for a single center point", ^{
    cv::Mat1b mask = cv::Mat1b(3, 3, 0.0);
    mask[1][1] = 255;
    std::vector<CGPoint> points = LTOuterBoundary(mask);
    expect(points.size()).to.equal(1);
    expect(points[0]).to.equal(CGPointMake(1, 1));
  });

  it(@"should return the correct points for a single edge point", ^{
    cv::Mat1b mask = cv::Mat1b(5, 5, 0.0);
    mask[0][1] = 255;
    std::vector<CGPoint> points = LTOuterBoundary(mask);
    expect(points.size()).to.equal(1);
    expect(points[0]).to.equal(CGPointMake(1, 0));
  });

  it(@"should return the correct points for a single corner point", ^{
    cv::Mat1b mask = cv::Mat1b(5, 5, 0.0);
    mask[0][0] = 255;
    std::vector<CGPoint> points = LTOuterBoundary(mask);
    expect(points.size()).to.equal(1);
    expect(points[0]).to.equal(CGPointMake(0, 0));
  });

  it(@"should return the correct points for a centered rect", ^{
    cv::Mat1b mask = cv::Mat1b(5, 5, 0.0);
    mask(cv::Rect(1, 1, 3, 3)).setTo(255);
    std::vector<CGPoint> points = LTOuterBoundary(mask);
    expect(points.size()).to.equal(4);
    expect(points[0]).to.equal(CGPointMake(1, 1));
    expect(points[1]).to.equal(CGPointMake(1, 3));
    expect(points[2]).to.equal(CGPointMake(3, 3));
    expect(points[3]).to.equal(CGPointMake(3, 1));
  });

  it(@"should return the correct outer points for a centered rect with hole", ^{
    cv::Mat1b mask = cv::Mat1b(8, 10, 0.0);
    mask(cv::Rect(1, 1, 8, 6)).setTo(255);
    mask(cv::Rect(3, 3, 4, 2)).setTo(0);

    std::vector<CGPoint> points = LTOuterBoundary(mask);
    expect(points.size()).to.equal(4);
    expect(points[0]).to.equal(CGPointMake(1, 1));
    expect(points[1]).to.equal(CGPointMake(1, 6));
    expect(points[2]).to.equal(CGPointMake(8, 6));
    expect(points[3]).to.equal(CGPointMake(8, 1));
  });

  it(@"should return one of the boundaries for two distinct rects", ^{
    cv::Mat1b mask = cv::Mat1b(8, 10, 0.0);
    mask(cv::Rect(1, 1, 3, 4)).setTo(255);
    mask(cv::Rect(5, 1, 4, 5)).setTo(255);

    std::vector<CGPoint> points = LTOuterBoundary(mask);
    expect(points.size()).to.equal(4);
    expect(points[0]).to.equal(CGPointMake(5, 1));
    expect(points[1]).to.equal(CGPointMake(5, 5));
    expect(points[2]).to.equal(CGPointMake(8, 5));
    expect(points[3]).to.equal(CGPointMake(8, 1));
  });

  it(@"should raise when attempting to compute boundary for mats of the wrong type", ^{
    expect(^{
      LTOuterBoundary(cv::Mat4b(1, 1));
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      LTOuterBoundary(cv::Mat1f(1, 1));
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"boundaries calculations", ^{
  it(@"should return no boundaries on an empty mask", ^{
    cv::Mat1b mask = cv::Mat1b(3, 3, 0.0);
    std::vector<std::vector<CGPoint>> boundaries = LTBoundaries(mask);
    expect(boundaries.size()).to.equal(0);
  });

  it(@"should return the correct points for a single center point", ^{
    cv::Mat1b mask = cv::Mat1b(3, 3, 0.0);
    mask[1][1] = 255;
    std::vector<std::vector<CGPoint>> boundaries = LTBoundaries(mask);
    expect(boundaries.size()).to.equal(1);
    expect(boundaries[0].size()).to.equal(1);
    expect(boundaries[0][0]).to.equal(CGPointMake(1, 1));
  });

  it(@"should return the correct points for a single edge point", ^{
    cv::Mat1b mask = cv::Mat1b(5, 5, 0.0);
    mask[0][1] = 255;
    std::vector<std::vector<CGPoint>> boundaries = LTBoundaries(mask);
    expect(boundaries.size()).to.equal(1);
    expect(boundaries[0].size()).to.equal(1);
    expect(boundaries[0][0]).to.equal(CGPointMake(1, 0));
  });

  it(@"should return the correct points for a single corner point", ^{
    cv::Mat1b mask = cv::Mat1b(5, 5, 0.0);
    mask[0][0] = 255;
    std::vector<std::vector<CGPoint>> boundaries = LTBoundaries(mask);
    expect(boundaries.size()).to.equal(1);
    expect(boundaries[0].size()).to.equal(1);
    expect(boundaries[0][0]).to.equal(CGPointMake(0, 0));
  });

  it(@"should return the correct points for three distinct points", ^{
    cv::Mat1b mask = cv::Mat1b(5, 5, 0.0);
    mask[0][0] = 255;
    mask[2][2] = 255;
    mask[3][4] = 255;

    std::vector<std::vector<CGPoint>> boundaries = LTBoundaries(mask);
    expect(boundaries.size()).to.equal(3);
    expect(boundaries[0].size()).to.equal(1);
    expect(boundaries[1].size()).to.equal(1);
    expect(boundaries[2].size()).to.equal(1);

    expect(boundaries[0][0]).to.equal(CGPointMake(4, 3));
    expect(boundaries[1][0]).to.equal(CGPointMake(2, 2));
    expect(boundaries[2][0]).to.equal(CGPointMake(0, 0));
  });

  it(@"should return the correct points for a centered rect", ^{
    cv::Mat1b mask = cv::Mat1b(5, 5, 0.0);
    mask(cv::Rect(1, 1, 3, 3)).setTo(255);
    std::vector<std::vector<CGPoint>> boundaries = LTBoundaries(mask);
    expect(boundaries.size()).to.equal(1);
    std::vector<CGPoint> points = boundaries[0];
    expect(points.size()).to.equal(4);
    expect(points[0]).to.equal(CGPointMake(1, 1));
    expect(points[1]).to.equal(CGPointMake(1, 3));
    expect(points[2]).to.equal(CGPointMake(3, 3));
    expect(points[3]).to.equal(CGPointMake(3, 1));
  });

  it(@"should return the correct outer points for two nested rects", ^{
    cv::Mat1b mask = cv::Mat1b(80, 100, 0.0);
    mask(cv::Rect(10, 10, 80, 60)).setTo(255);
    mask(cv::Rect(30, 30, 40, 20)).setTo(0);

    std::vector<std::vector<CGPoint>> boundaries = LTBoundaries(mask);
    expect(boundaries.size()).to.equal(2);
    std::vector<CGPoint> firstBoundary = boundaries[0];
    expect(firstBoundary.size()).to.equal(4);
    expect(firstBoundary[0]).to.equal(CGPointMake(30, 29));
    expect(firstBoundary[1]).to.equal(CGPointMake(70, 30));
    expect(firstBoundary[2]).to.equal(CGPointMake(69, 50));
    expect(firstBoundary[3]).to.equal(CGPointMake(29, 49));

    std::vector<CGPoint> secondBoundary = boundaries[1];
    expect(secondBoundary.size()).to.equal(4);
    expect(secondBoundary[0]).to.equal(CGPointMake(10, 10));
    expect(secondBoundary[1]).to.equal(CGPointMake(10, 69));
    expect(secondBoundary[2]).to.equal(CGPointMake(89, 69));
    expect(secondBoundary[3]).to.equal(CGPointMake(89, 10));
  });

  it(@"should return both boundaries for two distinct rects", ^{
    cv::Mat1b mask = cv::Mat1b(80, 100, 0.0);
    mask(cv::Rect(10, 10, 30, 40)).setTo(255);
    mask(cv::Rect(50, 10, 40, 50)).setTo(255);

    std::vector<std::vector<CGPoint>> boundaries = LTBoundaries(mask);
    expect(boundaries.size()).to.equal(2);

    std::vector<CGPoint> firstBoundary = boundaries[0];
    expect(firstBoundary.size()).to.equal(4);
    expect(firstBoundary[0]).to.equal(CGPointMake(50, 10));
    expect(firstBoundary[1]).to.equal(CGPointMake(50, 59));
    expect(firstBoundary[2]).to.equal(CGPointMake(89, 59));
    expect(firstBoundary[3]).to.equal(CGPointMake(89, 10));

    std::vector<CGPoint> secondBoundary = boundaries[1];
    expect(secondBoundary.size()).to.equal(4);
    expect(secondBoundary[0]).to.equal(CGPointMake(10, 10));
    expect(secondBoundary[1]).to.equal(CGPointMake(10, 49));
    expect(secondBoundary[2]).to.equal(CGPointMake(39, 49));
    expect(secondBoundary[3]).to.equal(CGPointMake(39, 10));
  });

  it(@"should raise when attempting to compute boundary for mats of the wrong type", ^{
    expect(^{
      LTBoundaries(cv::Mat4b(1, 1));
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      LTBoundaries(cv::Mat1f(1, 1));
    }).to.raise(NSInvalidArgumentException);
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
  it(@"should correctly compute whether a given polyline intersects itself", ^{
    CGPoint p0 = CGPointZero;
    CGPoint p1 = CGPointMake(1, 0);
    CGPoint p2 = CGPointMake(0.5, -0.5);
    CGPoint p3 = CGPointMake(0.5, 0.5);
    std::vector<CGPoint> pointsToCheck{p0, p1, p2, p3};
    expect(LTIsSelfIntersectingPolyline(pointsToCheck)).to.beTruthy();
    std::vector<CGPoint> pointsToCheck2{p0, p2, p3, p1};
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

  it(@"should correctly compute all intersection points of a given polyline", ^{
    CGPoint p0 = CGPointZero;
    CGPoint p1 = CGPointMake(1, 0);
    CGPoint p2 = CGPointMake(0.5, -0.5);
    CGPoint p3 = CGPointMake(0, 0.5);
    CGPoint p4 = CGPointMake(1, -0.5);
    std::vector<CGPoint> pointsToCheck{p0, p1, p2, p3, p4};
    std::vector<CGPoint> expectedIntersectionPoints =
        LTComputeIntersectionPointsOfPolyLine(pointsToCheck);
    expect(expectedIntersectionPoints.size()).to.equal(3);
    expect(expectedIntersectionPoints[0]).to.beCloseToPointWithin(CGPointMake(0.25, 0), kEpsilon);
    expect(expectedIntersectionPoints[1]).to.beCloseToPointWithin(CGPointMake(0.5, 0), kEpsilon);
    expect(expectedIntersectionPoints[2]).to.beCloseToPointWithin(CGPointMake(0.75, -0.25),
                                                                  kEpsilon);
  });

  it(@"should correctly compute all intersection points of two given polylines", ^{
    std::vector<CGPoint> polyline0{CGPointZero, CGPointMake(1, 0), CGPointMake(1, 1),
        CGPointMake(2, 1), CGPointMake(1, 2)};
    std::vector<CGPoint> polyline1{CGPointMake(0.5, -0.5), CGPointMake(0.5, 0.5),
        CGPointMake(1.5, 0.5), CGPointMake(1.5, 2)};
    std::vector<CGPoint> intersectionPoints =
        LTComputeIntersectionPointsOfPolyLines(polyline0, polyline1);
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
    std::vector<CGPoint> polyline0{CGPointZero, CGPointMake(1, 0), CGPointMake(1, 1),
        CGPointMake(2, 1), CGPointMake(1, 2)};
    std::vector<CGPoint> polyline1{CGPointMake(0.5, -0.5), CGPointMake(0.5, 0.5),
        CGPointMake(1.5, 0.5), CGPointMake(1.5, 2)};
    CGPointPair result = LTPointOnPolylineNearestToPointOnPolyline(polyline0, polyline1);
    expect(result.first).to.equal(CGPointMake(0.5, 0));
    expect(result.second).to.equal(CGPointMake(0.5, 0));

    polyline0 = std::vector<CGPoint>{CGPointMake(-0.5, -0.5), CGPointZero, CGPointMake(1, 0),
        CGPointMake(1.5, -0.5)};
    polyline1 = std::vector<CGPoint>{CGPointMake(0, 2), CGPointMake(0.5, 1), CGPointMake(1, 2)};
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

    context(@"closest point on polyline from point", ^{
      __block std::vector<CGPoint> polyline;

      beforeEach(^{
        polyline = std::vector<CGPoint>({CGPointMake(0, 0), CGPointMake(0, 1), CGPointMake(1, 1)});
      });

      it(@"should correctly compute the closest point from a point on the polyline points", ^{
        for(const CGPoint point : polyline) {
          expect(LTPointOnPolylineNearestToPoint(polyline, point)).to.equal(point);
        }
      });

      it(@"should correctly compute the closest point from a point on the polyline edges", ^{
        std::vector<CGPoint> pointsOnEdges({
          0.5 * (polyline[0] + polyline[1]),
          0.25 * polyline[1] + 0.75 * polyline[2]
        });

        for(const CGPoint point : pointsOnEdges) {
          expect(LTPointOnPolylineNearestToPoint(polyline, point)).to.equal(point);
        }
      });

      it(@"should correctly compute the closest point from a point on the polyline edges", ^{
        std::vector<CGPointPair> testPoints;
        testPoints.push_back({CGPointMake(2, 2), CGPointMake(1, 1)});
        testPoints.push_back({CGPointMake(0.5, 3), CGPointMake(0.5, 1)});
        testPoints.push_back({CGPointMake(-1, 3), CGPointMake(0, 1)});
        testPoints.push_back({CGPointMake(-5, -1), CGPointMake(0, 0)});
        testPoints.push_back({CGPointMake(5, -1), CGPointMake(1, 1)});

        for(CGPointPair points : testPoints) {
          expect(LTPointOnPolylineNearestToPoint(polyline, points.first)).to.equal(points.second);
        }
      });

      it(@"should raise when attempting to compute closest point for non-existing polyline", ^{
        expect(^{
          std::vector<CGPoint> emptyPolyline;
          LTPointOnPolylineNearestToPoint(emptyPolyline, CGPointZero);
        }).to.raise(NSInvalidArgumentException);
      });

      it(@"should raise when attempting to compute closest point for invalid polyline", ^{
        expect(^{
          std::vector<CGPoint> invalidPolyline;
          invalidPolyline.push_back({CGPointZero});
          LTPointOnPolylineNearestToPoint(invalidPolyline, CGPointZero);
        }).to.raise(NSInvalidArgumentException);
      });
    });

    context(@"distance of point from polyline", ^{
      __block std::vector<CGPoint> polyline;

      beforeEach(^{
        polyline = std::vector<CGPoint>({CGPointMake(0, 0), CGPointMake(0, 1), CGPointMake(1, 1)});
      });

      it(@"should compute the distance of the points of a polyline from the polyline itself", ^{
        for(const CGPoint point : polyline) {
          expect(LTDistanceFromPolyLine(polyline, point)).to.equal(0.0);
        }
      });

      it(@"should compute the distance of points on a polyline's edges from the polyline itself", ^{
        std::vector<CGPoint> pointsOnEdges({
          0.5 * (polyline[0] + polyline[1]),
          0.25 * polyline[1] + 0.75 * polyline[2]
        });

        for(const CGPoint point : pointsOnEdges) {
          expect(LTDistanceFromPolyLine(polyline, point)).to.equal(0.0);
        }
      });

      it(@"should compute the distance of points from a polyline", ^{
        std::vector<CGPointPair> testPoints;
        testPoints.push_back({CGPointMake(2, 2), CGPointMake(1, 1)});
        testPoints.push_back({CGPointMake(0.5, 3), CGPointMake(0.5, 1)});
        testPoints.push_back({CGPointMake(-1, 3), CGPointMake(0, 1)});
        testPoints.push_back({CGPointMake(-5, -1), CGPointMake(0, 0)});
        testPoints.push_back({CGPointMake(5, -1), CGPointMake(1, 1)});

        for(CGPointPair points : testPoints) {
          CGFloat expected = CGPointDistance(points.first, points.second);
          expect(LTDistanceFromPolyLine(polyline, points.first)).to.equal(expected);
        }
      });
    });
  });
});

SpecEnd
