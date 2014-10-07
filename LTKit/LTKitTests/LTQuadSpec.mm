// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuad.h"

#import "LTOpenCVExtensions.h"

static const CGFloat kEpsilon = 1e-5;

@interface LTQuad (ForTesting)
- (NSUInteger)indexOfConcavePoint;
+ (NSUInteger)numberOfNonLeftTurns:(const LTQuadCorners &)points;
@end

/// Implementation for the sake of correctness checking.
/// Transformation required to transform a rectangle with origin at (0, 0) and size (1, 1) such that
/// its projected corners coincide with the vertices of this quad.
///
/// @see http://stackoverflow.com/questions/9470493/transforming-a-rectangle-image-into-a-quadrilateral-using-a-catransform3d/12820877#12820877
static GLKMatrix3 LTTransformationForQuad(LTQuad *quad) {
  const CGRect rect = CGRectMake(0, 0, 1, 1);
  const CGFloat x1 = quad.v0.x;
  const CGFloat y1 = quad.v0.y;
  const CGFloat x2 = quad.v1.x;
  const CGFloat y2 = quad.v1.y;
  const CGFloat x3 = quad.v2.x;
  const CGFloat y3 = quad.v2.y;
  const CGFloat x4 = quad.v3.x;
  const CGFloat y4 = quad.v3.y;

  CGFloat X = rect.origin.x;
  CGFloat Y = rect.origin.y;
  CGFloat W = rect.size.width;
  CGFloat H = rect.size.height;

  CGFloat y21 = y2 - y1;
  CGFloat y32 = y4 - y2;
  CGFloat y43 = y3 - y4;
  CGFloat y14 = y1 - y3;
  CGFloat y31 = y4 - y1;
  CGFloat y42 = y3 - y2;

  CGFloat a = -H * (x2 * x4 * y14 + x2 * x3 * y31 - x1 * x3 * y32 + x1 * x4 * y42);
  CGFloat b = W * (x2 * x4 * y14 + x4 * x3 * y21 + x1 * x3 * y32 + x1 * x2 * y43);
  CGFloat c = H * X * (x2 * x4 * y14 + x2 * x3 * y31 - x1 * x3 * y32 + x1 * x4 * y42)
      - H * W * x1 * (x3 * y32 - x4 * y42 + x2 * y43)
      - W * Y * (x2 * x4 * y14 + x4 * x3 * y21 + x1 * x3 * y32 + x1 * x2 * y43);

  CGFloat d = H * (-x3 * y21 * y4 + x2 * y1 * y43 - x1 * y2 * y43 - x4 * y1 * y3 + x4 * y2 * y3);
  CGFloat e = W * (x3 * y2 * y31 - x4 * y1 * y42 - x2 * y31 * y3 + x1 * y4 * y42);
  CGFloat f = -(W * (x3 * (Y * y2 * y31 + H * y1 * y32)
                     - x4 * (H + Y) * y1 * y42 + H * x2 * y1 * y43 + x2 * Y * (y1 - y4) * y3
                     + x1 * Y * y4 * (-y2 + y3))
                - H * X * (x3 * y21 * y4 - x2 * y1 * y43 + x4 * (y1 - y2) * y3
                           + x1 * y2 * (-y4 + y3)));

  CGFloat g = H * (x4 * y21 - x3 * y21 + (-x1 + x2) * y43);
  CGFloat h = W * (-x2 * y31 + x3 * y31 + (x1 - x4) * y42);
  CGFloat i = W * Y * (x2 * y31 - x3 * y31 - x1 * y42 + x4 * y42)
      + H * (X * (-(x4 * y21) + x3 * y21 + x1 * y43 - x2 * y43)
             + W * (-(x4 * y2) + x3 * y2 + x2 * y4 - x3 * y4 - x2 * y3 + x4 * y3));

  if (std::abs(i) < kEpsilon) {
    i = kEpsilon * (i > 0 ? 1 : -1);
  }

  return GLKMatrix3Make(a / i, b / i, c / i, d / i, e / i, f / i, g / i, h / i, 1);
}

SpecBegin(LTQuad)

__block CGPoint v0;
__block CGPoint v1;
__block CGPoint v2;
__block CGPoint v3;
__block CGPoint w0;

__block LTQuad *quad;

beforeAll(^{
  v0 = CGPointMake(0, 0);
  v1 = CGPointMake(1, 0);
  v2 = CGPointMake(1, 0.9);
  v3 = CGPointMake(0, 1);
  w0 = CGPointMake(0.25, 0.25);
});

context(@"initializers and factory methods", ^{
  context(@"initializers", ^{
    it(@"should initialize with corners", ^{
      LTQuadCorners corners{{v0, v1, v2, v3}};
      quad = [[LTQuad alloc] initWithCorners:corners];
      expect(quad.v0).to.equal(v0);
      expect(quad.v1).to.equal(v1);
      expect(quad.v2).to.equal(v2);
      expect(quad.v3).to.equal(v3);
    });

    it(@"should fail to initialize if the corners of a convex quad are given in counterclockwise order", ^{
      LTQuadCorners cornersOfConvexQuad{{v3, v2, v1, v0}};
      expect(^{
        quad = [[LTQuad alloc] initWithCorners:cornersOfConvexQuad];
      }).to.raise(NSInternalInconsistencyException);
    });

    it(@"should fail to initialize if the corners of a concave quad are given in counterclockwise order", ^{
      LTQuadCorners cornersOfConcaveQuad{{v3, w0, v1, v0}};
      expect(^{
        quad = [[LTQuad alloc] initWithCorners:cornersOfConcaveQuad];
      }).to.raise(NSInternalInconsistencyException);
    });
  });

  context(@"factory Methods", ^{
    it(@"should create quad from rect", ^{
      quad = [LTQuad quadFromRect:CGRectMake(v0.x, v0.y, v1.x, v3.y)];
      expect(quad.v0).to.equal(v0);
      expect(quad.v1).to.equal(v1);
      expect(quad.v2).to.equal(CGPointMake(v1.x, v3.y));
      expect(quad.v3).to.equal(v3);
    });

    it(@"should create quad with origin and size", ^{
      CGRect rect = CGRectMake(v0.x, v0.y, v1.x, v3.y);
      quad = [LTQuad quadFromRectWithOrigin:rect.origin andSize:rect.size];
      expect(quad.v0).to.equal(v0);
      expect(quad.v1).to.equal(v1);
      expect(quad.v2).to.equal(CGPointMake(v1.x, v3.y));
      expect(quad.v3).to.equal(v3);
    });
  });
});

context(@"point inclusion", ^{
  it(@"should correctly compute point inclusion for a simple convex quad", ^{
    LTQuadCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    expect([quad containsPoint:v0]).to.beTruthy();
    expect([quad containsPoint:(v0 + v1) / 2]).to.beTruthy();
    expect([quad containsPoint:v1]).to.beTruthy();
    expect([quad containsPoint:v2]).to.beTruthy();
    expect([quad containsPoint:v3]).to.beTruthy();
    expect([quad containsPoint:w0]).to.beTruthy();
    expect([quad containsPoint:CGPointMake(-1, -1)]).to.beFalsy();
    expect([quad containsPoint:CGPointMake(0, -1)]).to.beFalsy();
    expect([quad containsPoint:CGPointMake(1, 1)]).to.beFalsy();
  });

  it(@"should correctly compute point inclusion for a simple concave quad", ^{
    LTQuadCorners corners{{v0, v1, w0, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    expect([quad containsPoint:v0]).to.beTruthy();
    expect([quad containsPoint:(v0 + v1) / 2]).to.beTruthy();
    expect([quad containsPoint:v1]).to.beTruthy();
    expect([quad containsPoint:w0]).to.beTruthy();
    expect([quad containsPoint:v2]).to.beFalsy();
    expect([quad containsPoint:(v0 + w0) / 2]).to.beTruthy();
    expect([quad containsPoint:CGPointMake(-1, -1)]).to.beFalsy();
    expect([quad containsPoint:CGPointMake(0, -1)]).to.beFalsy();
    expect([quad containsPoint:CGPointMake(1, 1)]).to.beFalsy();
  });

  it(@"should correctly compute point inclusion for a complex quad", ^{
    LTQuadCorners corners{{v0, v1, v3, v2}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    expect([quad containsPoint:v0]).to.beTruthy();
    expect([quad containsPoint:(v0 + v1) / 2]).to.beTruthy();
    expect([quad containsPoint:v1]).to.beTruthy();
    expect([quad containsPoint:v2]).to.beTruthy();
    expect([quad containsPoint:v3]).to.beTruthy();
    expect([quad containsPoint:w0]).to.beFalsy();
    expect([quad containsPoint:(v0 + v3) / 2]).to.beFalsy();
    expect([quad containsPoint:CGPointMake(0.25, 0.1)]).to.beTruthy();
    expect([quad containsPoint:CGPointMake(-1, -1)]).to.beFalsy();
    expect([quad containsPoint:CGPointMake(0, -1)]).to.beFalsy();
    expect([quad containsPoint:CGPointMake(1, 1)]).to.beFalsy();
  });

  it(@"should correctly compute the concave point of a concave quad", ^{
    LTQuadCorners cornersOfConcaveQuad{{v0, v1, w0, v3}};
    quad = [[LTQuad alloc] initWithCorners:cornersOfConcaveQuad];
    expect([quad indexOfConcavePoint]).to.equal(2);
  });

  it(@"should raise an exception when trying to compute the concave point of a convex quad", ^{
    LTQuadCorners cornersOfConvexQuad{{v0, v1, v2, v3}};
    quad = [[LTQuad alloc] initWithCorners:cornersOfConvexQuad];
    expect(^{
      [quad indexOfConcavePoint];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should raise an exception when trying to compute the concave point of a complex quad", ^{
    LTQuadCorners cornersOfComplexQuad{{v0, v1, v3, v2}};
    quad = [[LTQuad alloc] initWithCorners:cornersOfComplexQuad];
    expect(^{
      [quad indexOfConcavePoint];
    }).to.raise(NSInternalInconsistencyException);
  });
});

context(@"affine transformations", ^{
  it(@"should correctly rotate", ^{
    LTQuadCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    [quad rotateByAngle:13.7 / 180.0 * M_PI aroundPoint:CGPointMake(3, 1)];
    expect(quad.v0).to.beCloseToPointWithin(CGPointMake(0.322191, -0.682064), kEpsilon);
    expect(quad.v1).to.beCloseToPointWithin(CGPointMake(1.29374, -0.445225), kEpsilon);
    expect(quad.v2).to.beCloseToPointWithin(CGPointMake(1.08059, 0.429169), kEpsilon);
    expect(quad.v3).to.beCloseToPointWithin(CGPointMake(0.0853527, 0.289486), kEpsilon);
    expect(CGPointDistance(quad.v0, quad.v1)).to.beCloseToWithin(CGPointDistance(v0, v1), kEpsilon);
    expect(CGPointDistance(quad.v1, quad.v2)).to.beCloseToWithin(CGPointDistance(v1, v2), kEpsilon);
    expect(CGPointDistance(quad.v2, quad.v3)).to.beCloseToWithin(CGPointDistance(v2, v3), kEpsilon);
    expect(CGPointDistance(quad.v3, quad.v0)).to.beCloseToWithin(CGPointDistance(v3, v0), kEpsilon);
  });

  it(@"should correctly scale", ^{
    quad = [LTQuad quadFromRect:CGRectMake(0, 0, 1, 1)];
    [quad scale:2];
    expect(quad.v0).to.beCloseToPoint(CGPointMake(-0.5, -0.5));
    expect(quad.v1).to.beCloseToPoint(CGPointMake(1.5, -0.5));
    expect(quad.v2).to.beCloseToPoint(CGPointMake(1.5, 1.5));
    expect(quad.v3).to.beCloseToPoint(CGPointMake(-0.5, 1.5));
  });

  it(@"should correctly translate", ^{
    CGPoint translation = CGPointMake(2, 5);
    LTQuadCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    [quad translateCorners:LTQuadCornerRegionAll
             byTranslation:translation];
    expect(quad.v0).to.beCloseToPoint(v0 + translation);
    expect(quad.v1).to.beCloseToPoint(v1 + translation);
    expect(quad.v2).to.beCloseToPoint(v2 + translation);
    expect(quad.v3).to.beCloseToPoint(v3 + translation);

    quad = [[LTQuad alloc] initWithCorners:corners];
    [quad translateCorners:LTQuadCornerRegionV0
             byTranslation:translation];
    expect(quad.v0).to.beCloseToPoint(v0 + translation);
    expect(quad.v1).to.beCloseToPoint(v1);
    expect(quad.v2).to.beCloseToPoint(v2);
    expect(quad.v3).to.beCloseToPoint(v3);

    quad = [[LTQuad alloc] initWithCorners:corners];
    [quad translateCorners:LTQuadCornerRegionV2
             byTranslation:translation];
    expect(quad.v0).to.beCloseToPoint(v0);
    expect(quad.v1).to.beCloseToPoint(v1);
    expect(quad.v2).to.beCloseToPoint(v2 + translation);
    expect(quad.v3).to.beCloseToPoint(v3);
  });
});

context(@"copying", ^{
  it(@"should correctly copy", ^{
    LTQuadCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    LTQuad *copiedQuad = quad.copy;
    expect(copiedQuad).notTo.beIdenticalTo(quad);
    expect(copiedQuad.v0).to.equal(quad.v0);
    expect(copiedQuad.v1).to.equal(quad.v1);
    expect(copiedQuad.v2).to.equal(quad.v2);
    expect(copiedQuad.v3).to.equal(quad.v3);
  });
});

context(@"equality and similarity", ^{
  __block LTQuad *quad0;
  __block LTQuad *quad1;
  __block LTQuad *quad2;

  beforeEach(^{
    LTQuadCorners corners{{v0, v1, v2, v3}};
    quad0 = [[LTQuad alloc] initWithCorners:corners];
    quad1 = [[LTQuad alloc] initWithCorners:corners];
    corners = LTQuadCorners{{v0, v1, v2, v3 + CGPointMake(1e-8, 1e-8)}};
    quad2 = [[LTQuad alloc] initWithCorners:corners];
  });

  it(@"should correctly compute equality", ^{
    expect(quad0).toNot.beIdenticalTo(quad1);
    expect(quad1).toNot.beIdenticalTo(quad2);
    expect(quad2).toNot.beIdenticalTo(quad0);
    expect(quad0).to.equal(quad1);
    expect(quad1).to.equal(quad0);
    expect(quad1).toNot.equal(quad2);
    expect(quad2).toNot.equal(quad1);
    expect(quad2).toNot.equal(quad0);
    expect(quad0).toNot.equal(quad2);
  });

  it(@"should compute a correct hash value", ^{
    expect(quad0.hash).to.equal(quad1.hash);
    expect(quad0.hash).toNot.equal(quad2.hash);
  });

  it(@"should correctly compute similarity", ^{
    expect([quad0 isSimilarTo:quad1 upToDeviation:kEpsilon]).to.beTruthy();
    expect([quad1 isSimilarTo:quad2 upToDeviation:kEpsilon]).to.beTruthy();
    expect([quad2 isSimilarTo:quad0 upToDeviation:kEpsilon]).to.beTruthy();

    LTQuadCorners corners{{v0, v1, v2, v3 + CGPointMake(kEpsilon, 0)}};
    quad1 = [[LTQuad alloc] initWithCorners:corners];
    expect([quad0 isSimilarTo:quad1 upToDeviation:kEpsilon]).to.beTruthy();

    corners = LTQuadCorners{{v0, v1, v2, v3 + CGPointMake(2 * kEpsilon, 0)}};
    quad2 = [[LTQuad alloc] initWithCorners:corners];
    expect([quad0 isSimilarTo:quad2 upToDeviation:kEpsilon]).to.beFalsy();
  });
});

context(@"properties", ^{
  it(@"should correctly compute the bounding rect", ^{
    LTQuadCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    CGRect expectedBoundingRect = CGRectMake(v0.x, v0.y, v1.x, v3.y);
    expect(quad.boundingRect).to.equal(expectedBoundingRect);
  });

  it(@"should correctly compute the center", ^{
    quad = [LTQuad quadFromRect:CGRectMake(0, 0, 1, 1)];
    expect(quad.center).to.beCloseToPoint(CGPointMake(0.5, 0.5));
    LTQuadCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    expect(quad.center).to.beCloseToPoint((v0 + v1 + v2 + v3) / 4);
  });

  it(@"should correctly compute whether it is convex or concave", ^{
    LTQuad *convexQuad =
        [LTQuad quadFromRect:CGRectMake(v0.x, v0.y, v1.x, v3.y)];
    expect(convexQuad.isConvex).to.beTruthy();
    LTQuadCorners cornersOfConvexQuad{{v0, v1, v2, v3}};
    convexQuad = [[LTQuad alloc] initWithCorners:cornersOfConvexQuad];
    expect(convexQuad.isConvex).to.beTruthy();
    LTQuadCorners cornersOfConcaveQuad{{v0, v1, w0, v3}};
    LTQuad *concaveQuad = [[LTQuad alloc] initWithCorners:cornersOfConcaveQuad];
    expect(concaveQuad.isConvex).to.beFalsy();
  });

  it(@"should correctly compute whether it is self-intersecting or not",^{
    LTQuadCorners cornersOfConvexQuad{{v0, v1, v2, v3}};
    quad = [[LTQuad alloc] initWithCorners:cornersOfConvexQuad];
    expect(quad.isSelfIntersecting).to.beFalsy();
    LTQuadCorners cornersOfSimpleConcaveQuad{{v0, v1, w0, v3}};
    quad = [[LTQuad alloc] initWithCorners:cornersOfSimpleConcaveQuad];
    expect(quad.isSelfIntersecting).to.beFalsy();
    LTQuadCorners cornersOfComplexQuad{{v0, v1, v3, v2}};
    quad = [[LTQuad alloc] initWithCorners:cornersOfComplexQuad];
    expect(quad.isSelfIntersecting).to.beTruthy();
  });

  context(@"transformation", ^{
    it(@"should provide the correct transformation for axis-aligned quads", ^{
      quad = [LTQuad quadFromRect:CGRectMake(0, 0, 1, 1)];
      cv::Mat1f identity = cv::Mat1f::eye(3, 3);
      expect($(LTMatFromGLKMatrix3(quad.transform))).to.beCloseToMatWithin($(identity), kEpsilon);
      expect($(LTMatFromGLKMatrix3(LTTransformationForQuad(quad)))).to.beCloseToMatWithin($(identity),
                                                                                          kEpsilon);
    });

    it(@"should provide the correct transformation for non-axis-aligned quads", ^{
      // In iOS, negative values mean clockwise rotation, while positive values in OSX.
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
      const CGFloat kClockwiseAngle = -45.0 / 180.0 * M_PI;
#else
      const CGFloat kClockwiseAngle = 45.0 / 180.0 * M_PI;
#endif

      LTQuadCorners corners0{{CGPointMake(0, 0),
                                       CGPointMake(M_SQRT1_2, M_SQRT1_2),
                                       CGPointMake(0, M_SQRT2),
                                       CGPointMake(-M_SQRT1_2, M_SQRT1_2)}};
      quad = [[LTQuad alloc] initWithCorners:corners0];
      GLKMatrix3 expectedTransform = GLKMatrix3MakeRotation(kClockwiseAngle, 0, 0, 1);
      expect($(LTMatFromGLKMatrix3(quad.transform))).to.beCloseToMatWithin($(LTMatFromGLKMatrix3(expectedTransform)),
                                                                           kEpsilon);
      expect($(LTMatFromGLKMatrix3(LTTransformationForQuad(quad)))).to.beCloseToMatWithin($(LTMatFromGLKMatrix3(expectedTransform)),
                                                                                          kEpsilon);

      LTQuadCorners corners1{{CGPointMake(5.1, -2.7),
                              CGPointMake(19.2, 22.2),
                              CGPointMake(44.34, 190.2),
                              CGPointMake(-29.132, 99.1)}};
      quad = [[LTQuad alloc] initWithCorners:corners1];
      expect($(LTMatFromGLKMatrix3(quad.transform))).to.beCloseToMatWithin($(LTMatFromGLKMatrix3(LTTransformationForQuad(quad))),
                                                                           kEpsilon);
    });
  });
});

context(@"helper methods", ^{
  it(@"should correctly compute the number of non-left turns", ^{
    LTQuadCorners cornersOfConvexQuad{{v0, v1, v2, v3}};
    expect([LTQuad numberOfNonLeftTurns:cornersOfConvexQuad]).to.equal(4);
    LTQuadCorners cornersOfConcaveQuad{{v0, v1, w0, v3}};
    expect([LTQuad numberOfNonLeftTurns:cornersOfConcaveQuad]).to.equal(3);
    LTQuadCorners cornersOfComplexQuad{{v0, v1, v3, v2}};
    expect([LTQuad numberOfNonLeftTurns:cornersOfComplexQuad]).to.equal(2);
  });
});

SpecEnd
