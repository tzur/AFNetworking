// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuadrilateral.h"

static const CGFloat kEpsilon = 1e-5;

@interface LTQuadrilateral (ForTesting)
- (NSUInteger)indexOfConcavePoint;
+ (NSUInteger)numberOfNonLeftTurns:(const LTQuadrilateralCorners &)points;
@end

/// Implementation for the sake of correctness checking.
/// Transformation required to transform a rectangle with origin at (0, 0) and size (1, 1) such that
/// its projected corners coincide with the vertices of this quadrilateral.
///
/// @see http://stackoverflow.com/questions/9470493/transforming-a-rectangle-image-into-a-quadrilateral-using-a-catransform3d/12820877#12820877
static CATransform3D LTTransformationForQuad(LTQuadrilateral *quad) {
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

  return {a / i, d / i, 0, g / i, b / i, e / i, 0, h / i, 0, 0, 1, 0, c / i, f / i, 0, 1};
}

SpecBegin(LTQuadrilateral)

__block CGPoint v0;
__block CGPoint v1;
__block CGPoint v2;
__block CGPoint v3;
__block CGPoint w0;

__block LTQuadrilateral *quad;

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
      LTQuadrilateralCorners corners{{v0, v1, v2, v3}};
      quad = [[LTQuadrilateral alloc] initWithCorners:corners];
      expect(quad.v0).to.equal(v0);
      expect(quad.v1).to.equal(v1);
      expect(quad.v2).to.equal(v2);
      expect(quad.v3).to.equal(v3);
    });

    it(@"should fail to initialize if the corners of a convex quad are given in counterclockwise order", ^{
      LTQuadrilateralCorners cornersOfConvexQuad{{v3, v2, v1, v0}};
      expect(^{
        quad = [[LTQuadrilateral alloc] initWithCorners:cornersOfConvexQuad];
      }).to.raise(NSInternalInconsistencyException);
    });

    it(@"should fail to initialize if the corners of a concave quad are given in counterclockwise order", ^{
      LTQuadrilateralCorners cornersOfConcaveQuad{{v3, w0, v1, v0}};
      expect(^{
        quad = [[LTQuadrilateral alloc] initWithCorners:cornersOfConcaveQuad];
      }).to.raise(NSInternalInconsistencyException);
    });
  });

  context(@"factory Methods", ^{
    it(@"should create quadrilateral from rect", ^{
      quad = [LTQuadrilateral quadrilateralFromRect:CGRectMake(v0.x, v0.y, v1.x, v3.y)];
      expect(quad.v0).to.equal(v0);
      expect(quad.v1).to.equal(v1);
      expect(quad.v2).to.equal(CGPointMake(v1.x, v3.y));
      expect(quad.v3).to.equal(v3);
    });

    it(@"should create quadrilateral with origin and size", ^{
      CGRect rect = CGRectMake(v0.x, v0.y, v1.x, v3.y);
      quad = [LTQuadrilateral quadrilateralFromRectWithOrigin:rect.origin andSize:rect.size];
      expect(quad.v0).to.equal(v0);
      expect(quad.v1).to.equal(v1);
      expect(quad.v2).to.equal(CGPointMake(v1.x, v3.y));
      expect(quad.v3).to.equal(v3);
    });
  });
});

context(@"point inclusion", ^{
  it(@"should correctly compute point inclusion for a simple convex quadrilateral", ^{
    LTQuadrilateralCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuadrilateral alloc] initWithCorners:corners];
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

  it(@"should correctly compute point inclusion for a simple concave quadrilateral", ^{
    LTQuadrilateralCorners corners{{v0, v1, w0, v3}};
    quad = [[LTQuadrilateral alloc] initWithCorners:corners];
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

  it(@"should correctly compute point inclusion for a complex quadrilateral", ^{
    LTQuadrilateralCorners corners{{v0, v1, v3, v2}};
    quad = [[LTQuadrilateral alloc] initWithCorners:corners];
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

  it(@"should correctly compute the concave point of a concave quadrilateral", ^{
    LTQuadrilateralCorners cornersOfConcaveQuad{{v0, v1, w0, v3}};
    quad = [[LTQuadrilateral alloc] initWithCorners:cornersOfConcaveQuad];
    expect([quad indexOfConcavePoint]).to.equal(2);
  });

  it(@"should raise an exception when trying to compute the concave point of a convex quadrilateral", ^{
    LTQuadrilateralCorners cornersOfConvexQuad{{v0, v1, v2, v3}};
    quad = [[LTQuadrilateral alloc] initWithCorners:cornersOfConvexQuad];
    expect(^{
      [quad indexOfConcavePoint];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should raise an exception when trying to compute the concave point of a complex quadrilateral", ^{
    LTQuadrilateralCorners cornersOfComplexQuad{{v0, v1, v3, v2}};
    quad = [[LTQuadrilateral alloc] initWithCorners:cornersOfComplexQuad];
    expect(^{
      [quad indexOfConcavePoint];
    }).to.raise(NSInternalInconsistencyException);
  });
});

context(@"affine transformations", ^{
  it(@"should correctly rotate", ^{
    LTQuadrilateralCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuadrilateral alloc] initWithCorners:corners];
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
    quad = [LTQuadrilateral quadrilateralFromRect:CGRectMake(0, 0, 1, 1)];
    [quad scale:2];
    expect(quad.v0).to.beCloseToPoint(CGPointMake(-0.5, -0.5));
    expect(quad.v1).to.beCloseToPoint(CGPointMake(1.5, -0.5));
    expect(quad.v2).to.beCloseToPoint(CGPointMake(1.5, 1.5));
    expect(quad.v3).to.beCloseToPoint(CGPointMake(-0.5, 1.5));
  });

  it(@"should correctly translate", ^{
    CGPoint translation = CGPointMake(2, 5);
    LTQuadrilateralCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuadrilateral alloc] initWithCorners:corners];
    [quad translate:translation];
    expect(quad.v0).to.beCloseToPoint(v0 + translation);
    expect(quad.v1).to.beCloseToPoint(v1 + translation);
    expect(quad.v2).to.beCloseToPoint(v2 + translation);
    expect(quad.v3).to.beCloseToPoint(v3 + translation);
  });
});

context(@"properties", ^{
  it(@"should correctly compute the bounding rect", ^{
    LTQuadrilateralCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuadrilateral alloc] initWithCorners:corners];
    CGRect expectedBoundingRect = CGRectMake(v0.x, v0.y, v1.x, v3.y);
    expect(quad.boundingRect).to.equal(expectedBoundingRect);
  });

  it(@"should correctly compute the center", ^{
    quad = [LTQuadrilateral quadrilateralFromRect:CGRectMake(0, 0, 1, 1)];
    expect(quad.center).to.beCloseToPoint(CGPointMake(0.5, 0.5));
    LTQuadrilateralCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuadrilateral alloc] initWithCorners:corners];
    expect(quad.center).to.beCloseToPoint((v0 + v1 + v2 + v3) / 4);
  });

  it(@"should correctly compute whether it is convex or concave", ^{
    LTQuadrilateral *convexQuad =
        [LTQuadrilateral quadrilateralFromRect:CGRectMake(v0.x, v0.y, v1.x, v3.y)];
    expect(convexQuad.isConvex).to.beTruthy();
    LTQuadrilateralCorners cornersOfConvexQuad{{v0, v1, v2, v3}};
    convexQuad = [[LTQuadrilateral alloc] initWithCorners:cornersOfConvexQuad];
    expect(convexQuad.isConvex).to.beTruthy();
    LTQuadrilateralCorners cornersOfConcaveQuad{{v0, v1, w0, v3}};
    LTQuadrilateral *concaveQuad = [[LTQuadrilateral alloc] initWithCorners:cornersOfConcaveQuad];
    expect(concaveQuad.isConvex).to.beFalsy();
  });

  it(@"should correctly compute whether it is self-intersecting or not",^{
    LTQuadrilateralCorners cornersOfConvexQuadrilateral{{v0, v1, v2, v3}};
    quad = [[LTQuadrilateral alloc] initWithCorners:cornersOfConvexQuadrilateral];
    expect(quad.isSelfIntersecting).to.beFalsy();
    LTQuadrilateralCorners cornersOfSimpleConcaveQuadrilateral{{v0, v1, w0, v3}};
    quad = [[LTQuadrilateral alloc] initWithCorners:cornersOfSimpleConcaveQuadrilateral];
    expect(quad.isSelfIntersecting).to.beFalsy();
    LTQuadrilateralCorners cornersOfComplexQuadrilateral{{v0, v1, v3, v2}};
    quad = [[LTQuadrilateral alloc] initWithCorners:cornersOfComplexQuadrilateral];
    expect(quad.isSelfIntersecting).to.beTruthy();
  });

  context(@"transformation", ^{
    it(@"should provide the correct transformation for axis-aligned quadrilaterals", ^{
      quad = [LTQuadrilateral quadrilateralFromRect:CGRectMake(0, 0, 1, 1)];
      expect($(quad.transform)).to.beCloseToCATransform3DWithin(CATransform3DIdentity, kEpsilon);
      expect($(LTTransformationForQuad(quad))).to.beCloseToCATransform3DWithin(CATransform3DIdentity,
                                                                             kEpsilon);
    });

    it(@"should provide the correct transformation for non-axis-aligned quadrilaterals", ^{
      // In iOS, negative values mean clockwise rotation, while positive values in OSX.
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
      const CGFloat kClockwiseAngle = -45.0 / 180.0 * M_PI;
#else
      const CGFloat kClockwiseAngle = 45.0 / 180.0 * M_PI;
#endif

      LTQuadrilateralCorners corners0{{CGPointMake(0, 0),
                                       CGPointMake(M_SQRT1_2, M_SQRT1_2),
                                       CGPointMake(0, M_SQRT2),
                                       CGPointMake(-M_SQRT1_2, M_SQRT1_2)}};
      quad = [[LTQuadrilateral alloc] initWithCorners:corners0];
      CATransform3D expectedTransform = CATransform3DMakeRotation(-kClockwiseAngle, 0, 0, 1);
      expect($(quad.transform)).to.beCloseToCATransform3DWithin(expectedTransform, kEpsilon);
      expect($(LTTransformationForQuad(quad))).to.beCloseToCATransform3DWithin(expectedTransform,
                                                                             kEpsilon);

      LTQuadrilateralCorners corners1{{CGPointMake(5.1, -2.7),
                                       CGPointMake(19.2, 22.2),
                                       CGPointMake(44.34, 190.2),
                                       CGPointMake(-29.132, 99.1)}};
      quad = [[LTQuadrilateral alloc] initWithCorners:corners1];
      expect($(quad.transform)).to.beCloseToCATransform3DWithin(LTTransformationForQuad(quad),
                                                                kEpsilon);
    });
  });
});

context(@"helper methods", ^{
  it(@"should correctly compute the number of non-left turns", ^{
    LTQuadrilateralCorners cornersOfConvexQuad{{v0, v1, v2, v3}};
    expect([LTQuadrilateral numberOfNonLeftTurns:cornersOfConvexQuad]).to.equal(4);
    LTQuadrilateralCorners cornersOfConcaveQuad{{v0, v1, w0, v3}};
    expect([LTQuadrilateral numberOfNonLeftTurns:cornersOfConcaveQuad]).to.equal(3);
    LTQuadrilateralCorners cornersOfComplexQuad{{v0, v1, v3, v2}};
    expect([LTQuadrilateral numberOfNonLeftTurns:cornersOfComplexQuad]).to.equal(2);
  });
});

SpecEnd
