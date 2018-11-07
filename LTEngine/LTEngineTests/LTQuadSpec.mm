// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuad.h"

#import <LTEngine/LTGLKitExtensions.h>
#import <LTKit/LTRandom.h>
#import <opencv2/calib3d.hpp>

#import "LTOpenCVExtensions.h"
#import "LTRotatedRect.h"

static const CGFloat kEpsilon = 1e-5;

static cv::Mat1f LTMatWithQuad(const lt::Quad &quad) {
  return (cv::Mat1f(4, 2) << quad.v0().x, quad.v0().y, quad.v1().x, quad.v1().y,
                             quad.v2().x, quad.v2().y, quad.v3().x, quad.v3().y);
}

/// Implementation for the sake of correctness checking.
/// Transformation required to transform a rectangle with origin at (0, 0) and size (1, 1) such that
/// its projected corners coincide with the vertices of the given \c quad.
static GLKMatrix3 LTTransformationForQuad(const lt::Quad &quad) {
  CGRect rect = CGRectMake(0, 0, 1, 1);
  cv::Mat1f sourceMatrix = LTMatWithQuad(lt::Quad(rect));
  cv::Mat destinationMatrix = LTMatWithQuad(quad);
  cv::Mat1f homography = cv::findHomography(sourceMatrix, destinationMatrix);
  return GLKMatrix3MakeWithArray((float *)homography.data);
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
      expect(quad.corners == corners).to.beTruthy();
      expect(quad.v0).to.equal(v0);
      expect(quad.v1).to.equal(v1);
      expect(quad.v2).to.equal(v2);
      expect(quad.v3).to.equal(v3);
    });

    it(@"should distinguish between valid and invalid input corners", ^{
      LTQuadCorners nonDegenerateCorners{{v0, v1, v2, v3}};
      expect([LTQuad validityOfCorners:nonDegenerateCorners]).to.equal(LTQuadCornersValidityValid);

      LTQuadCorners cornersOfConvexQuadInCounterClockWiseOrder{{v3, v2, v1, v0}};
      expect([LTQuad validityOfCorners:cornersOfConvexQuadInCounterClockWiseOrder]).to.
          equal(LTQuadCornersValidityInvalidDueToOrder);

      LTQuadCorners nullCorners{{v3, v2, CGPointNull, v0}};
      expect([LTQuad validityOfCorners:nullCorners]).to.
          equal(LTQuadCornersValidityInvalidDueToNull);

      LTQuadCorners cornersOfConcaveQuadInCounterClockWiseOrder{{v3, w0, v1, v0}};
      expect([LTQuad validityOfCorners:cornersOfConcaveQuadInCounterClockWiseOrder]).to.
          equal(LTQuadCornersValidityInvalidDueToOrder);

      LTQuadCorners threeCollinearCorners{{v0, v0 + CGPointMake(1, 0), v0 + CGPointMake(2, 0),
        v0 + CGPointMake(1, 1)}};
      expect([LTQuad validityOfCorners:threeCollinearCorners]).to.equal(LTQuadCornersValidityValid);

      LTQuadCorners fourCollinearCorners{{v0, v0 + CGPointMake(1, 0), v0 + CGPointMake(2, 0),
          v0 + CGPointMake(3, 0)}};
      expect([LTQuad validityOfCorners:fourCollinearCorners]).to.
          equal(LTQuadCornersValidityInvalidDueToCollinearity);

      LTQuadCorners fourCollinearCorners2{{v0, v0 + CGPointMake(1, 0), v0 + CGPointMake(2, 0),
        v0 + CGPointMake(1.5, 0)}};
      expect([LTQuad validityOfCorners:fourCollinearCorners2]).to.
          equal(LTQuadCornersValidityInvalidDueToCollinearity);

      LTQuadCorners closeButNotTooCloseCorners{{v0, v0 + CGPointMake(1e-7, 0), v1, v2}};
      expect([LTQuad validityOfCorners:closeButNotTooCloseCorners]).to.
          equal(LTQuadCornersValidityValid);

      LTQuadCorners tooCloseCorners{{v0, v0 + CGPointMake(1e-12, 0), v1, v2}};
      expect([LTQuad validityOfCorners:tooCloseCorners]).to.
          equal(LTQuadCornersValidityInvalidDueToProximity);
    });

    it(@"should fail if corners are given in counterclockwise order", ^{
      LTQuadCorners cornersOfConvexQuadInCounterClockWiseOrder{{v3, v2, v1, v0}};
      expect(^{
        quad = [[LTQuad alloc] initWithCorners:cornersOfConvexQuadInCounterClockWiseOrder];
      }).to.raise(NSInvalidArgumentException);

      LTQuadCorners cornersOfConcaveQuadInCounterClockWiseOrder{{v3, w0, v1, v0}};
      expect(^{
        quad = [[LTQuad alloc] initWithCorners:cornersOfConcaveQuadInCounterClockWiseOrder];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"factory Methods", ^{
    it(@"should create quad from vertices of given quad", ^{
      quad = [[LTQuad alloc] initWithCorners:{{v0, v1, v2, v3}}];
      LTQuad *newQuad = [LTQuad quadWithVerticesOfQuad:quad];
      expect(newQuad.v0).to.equal(quad.v0);
      expect(newQuad.v1).to.equal(quad.v1);
      expect(newQuad.v2).to.equal(quad.v2);
      expect(newQuad.v3).to.equal(quad.v3);
    });

    it(@"should create quad from rect", ^{
      quad = [LTQuad quadFromRect:CGRectMake(v0.x, v0.y, v1.x, v3.y)];
      expect(quad.v0).to.equal(v0);
      expect(quad.v1).to.equal(v1);
      expect(quad.v2).to.equal(CGPointMake(v1.x, v3.y));
      expect(quad.v3).to.equal(v3);
    });

    it(@"should return nil when creating quad from rect invalid for initialization", ^{
      CGFloat edgeLength = 1e-12;
      quad = [LTQuad quadFromRect:CGRectFromSize(CGSizeMakeUniform(edgeLength))];
      expect(quad).to.beNil();
    });

    it(@"should create quad with origin and size", ^{
      CGRect rect = CGRectMake(v0.x, v0.y, v1.x, v3.y);
      quad = [LTQuad quadFromRectWithOrigin:rect.origin andSize:rect.size];
      expect(quad.v0).to.equal(v0);
      expect(quad.v1).to.equal(v1);
      expect(quad.v2).to.equal(CGPointMake(v1.x, v3.y));
      expect(quad.v3).to.equal(v3);
    });

    it(@"should return nil when creating quad with origin and size invalid for initialization", ^{
      CGFloat edgeLength = 1e-12;
      quad = [LTQuad quadFromRectWithOrigin:CGPointZero andSize:CGSizeMakeUniform(edgeLength)];
      expect(quad).to.beNil();
    });

    it(@"should create quad from rotated rect", ^{
      LTRotatedRect *rotatedRect = [LTRotatedRect rect:CGRectMake(v0.x, v0.y, v1.x, v3.y)];
      quad = [LTQuad quadFromRotatedRect:rotatedRect];
      expect(quad.v0).to.equal(rotatedRect.v0);
      expect(quad.v1).to.equal(rotatedRect.v1);
      expect(quad.v2).to.equal(rotatedRect.v2);
      expect(quad.v3).to.equal(rotatedRect.v3);
    });

    it(@"should return nil when creating quad from rotated rect invalid for initialization", ^{
      CGFloat edgeLength = 1e-12;
      LTRotatedRect *rotatedRect =
          [LTRotatedRect rect:CGRectFromSize(CGSizeMakeUniform(edgeLength)) withAngle:M_PI_4];
      quad = [LTQuad quadFromRotatedRect:rotatedRect];
      expect(quad).to.beNil();
    });

    it(@"should create quad from a given rect transformed by the transform of a given quad", ^{
      // Canonical 1x1 square.
      LTQuad *transformQuad = [LTQuad quadFromRect:CGRectFromSize(CGSizeMakeUniform(1))];
      quad = [LTQuad quadFromRect:CGRectFromSize(CGSizeMakeUniform(1))
              transformedByTransformOfQuad:transformQuad];
      expect([quad isSimilarTo:transformQuad upToDeviation:kEpsilon]).to.beTruthy();

      // Axis-aligned rect scaled in x-direction.
      transformQuad = [LTQuad quadFromRect:CGRectMake(-0.5, 0, 2, 1)];
      quad = [LTQuad quadFromRect:CGRectFromSize(CGSizeMakeUniform(1))
              transformedByTransformOfQuad:transformQuad];
      expect([quad isSimilarTo:transformQuad upToDeviation:kEpsilon]).to.beTruthy();

      // Axis-aligned square scaled uniformly.
      transformQuad = [LTQuad quadFromRect:CGRectFromSize(CGSizeMakeUniform(2))];
      quad = [LTQuad quadFromRect:CGRectFromSize(CGSizeMakeUniform(2))
              transformedByTransformOfQuad:transformQuad];
      LTQuad *expectedQuad = [LTQuad quadFromRect:CGRectFromSize(CGSizeMakeUniform(4))];
      expect([quad isSimilarTo:expectedQuad upToDeviation:kEpsilon]).to.beTruthy();

      // Rotated square.
      LTQuadCorners corners{{CGPointMake(-1, 0), CGPointMake(0, -1), CGPointMake(1, 0),
        CGPointMake(0, 1)
      }};
      transformQuad = [[LTQuad alloc] initWithCorners:corners];
      quad = [LTQuad quadFromRect:CGRectMake(0, 0, 2, 1)
              transformedByTransformOfQuad:transformQuad];
      corners = LTQuadCorners{{CGPointMake(-1, 0), CGPointMake(1, -2), CGPointMake(2, -1),
        CGPointMake(0, 1)
      }};
      expectedQuad = [[LTQuad alloc] initWithCorners:corners];
      expect([quad isSimilarTo:expectedQuad upToDeviation:kEpsilon]).to.beTruthy();

      // Non-rectangular quad.
      corners = LTQuadCorners{{CGPointZero, CGPointMake(1, 0), CGPointMake(0.75, 1),
        CGPointMake(0.25, 1)
      }};
      transformQuad = [[LTQuad alloc] initWithCorners:corners];
      quad = [LTQuad quadFromRect:CGRectMake(0, 0, 1, 0.5)
              transformedByTransformOfQuad:transformQuad];
      corners = LTQuadCorners{{CGPointZero, CGPointMake(1, 0), CGPointMake(0.833333, 0.666667),
        CGPointMake(0.166667, 0.666667)
      }};
      expectedQuad = [[LTQuad alloc] initWithCorners:corners];
      expect([quad isSimilarTo:expectedQuad upToDeviation:kEpsilon]).to.beTruthy();
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

  it(@"should correctly compute vertex inclusion", ^{
    quad = [[LTQuad alloc] initWithCorners:{{v0, v1, v3, v2}}];
    LTQuad *anotherQuad = [LTQuad quadFromRect:CGRectMake(-1, -1, 1, 1)];
    expect([quad containsVertexOfQuad:anotherQuad]).to.beTruthy();
    anotherQuad = [LTQuad quadFromRect:CGRectMake(0.5, 0.5, 0.2, 0.2)];
    expect([quad containsVertexOfQuad:anotherQuad]).to.beTruthy();
    anotherQuad = [LTQuad quadFromRect:CGRectMake(-1, -1, 0.5, 0.5)];
    expect([quad containsVertexOfQuad:anotherQuad]).to.beFalsy();
    anotherQuad = [LTQuad quadFromRect:CGRectMake(-1, -1, 2, 2)];
    expect([quad containsVertexOfQuad:anotherQuad]).to.beFalsy();

    quad = [[LTQuad alloc] initWithCorners:{{v0, v1, w0, v2}}];
    anotherQuad = [LTQuad quadFromRect:CGRectMake(-1, -1, 1, 1)];
    expect([quad containsVertexOfQuad:anotherQuad]).to.beTruthy();
    anotherQuad = [LTQuad quadFromRect:CGRectMake(-0.1, -0.2, 0.3, 0.3)];
    expect([quad containsVertexOfQuad:anotherQuad]).to.beTruthy();
    anotherQuad = [LTQuad quadFromRect:CGRectMake(0.1, -0.5, 10, 1)];
    expect([quad containsVertexOfQuad:anotherQuad]).to.beFalsy();
    anotherQuad = [LTQuad quadFromRect:CGRectMake(-1, -1, 3, 3)];
    expect([quad containsVertexOfQuad:anotherQuad]).to.beFalsy();
  });

  it(@"should correctly compute the closest point on any of its edges from a given point", ^{
    quad = [LTQuad quadFromRect:CGRectMake(0, 0, 1, 1)];
    CGPoint point = CGPointMake(-0.5, -0.5);
    expect([quad pointOnEdgeClosestToPoint:point]).to.beCloseToPointWithin(quad.v0, kEpsilon);

    point = CGPointMake(0.75, -0.5);
    expect([quad pointOnEdgeClosestToPoint:point]).to.beCloseToPointWithin(CGPointMake(0.75, 0),
                                                                           kEpsilon);

    point = CGPointMake(1.5, -0.5);
    expect([quad pointOnEdgeClosestToPoint:point]).to.beCloseToPointWithin(quad.v1, kEpsilon);

    point = CGPointMake(0.9, 0.1);
    expect([quad pointOnEdgeClosestToPoint:point]).to.beCloseToPointWithin(CGPointMake(0.9, 0),
                                                                           kEpsilon);

    point = CGPointMake(100, 1);
    expect([quad pointOnEdgeClosestToPoint:point]).to.beCloseToPointWithin(quad.v2, kEpsilon);

    point = CGPointMake(-0.4, 1);
    expect([quad pointOnEdgeClosestToPoint:point]).to.beCloseToPointWithin(quad.v3, kEpsilon);
  });

  it(@"should correctly compute the points with minimum distance located on edges of two quads", ^{
    quad = [LTQuad quadFromRect:CGRectMake(0, 0, 1, 1)];
    LTQuad *anotherQuad = [LTQuad quadFromRect:CGRectMake(0.5, 1.5, 1, 1)];
    CGPointPair result = [quad nearestPoints:anotherQuad];
    expect(result.first).to.beCloseToPointWithin(CGPointMake(1, 1), kEpsilon);
    expect(result.second).to.beCloseToPointWithin(CGPointMake(1, 1.5), kEpsilon);

    quad = [[LTQuad alloc] initWithCorners:LTQuadCorners{{CGPointZero, CGPointMake(1, 0),
        CGPointMake(1.5, 0.5), CGPointMake(1.5, 1)}}];
    anotherQuad = [LTQuad quadFromRect:CGRectMake(0, 2, 1, 1)];
    result = [quad nearestPoints:anotherQuad];
    expect(result.first).to.beCloseToPointWithin(quad.v3, kEpsilon);
    expect(result.second).to.beCloseToPointWithin(anotherQuad.v1, kEpsilon);

    anotherQuad = [LTQuad quadFromRect:CGRectMake(-0.5, -0.5, 1, 1)];
    result = [quad nearestPoints:anotherQuad];
    expect(result.first).to.beCloseToPointWithin(CGPointMake(0.5, 0), kEpsilon);
    expect(result.second).to.beCloseToPointWithin(CGPointMake(0.5, 0), kEpsilon);
  });
});

context(@"transformability", ^{
  __block CGPoint translation;
  __block CGFloat rotation;
  __block CGFloat scaling;

  beforeEach(^{
    LTQuadCorners corners{{10 * v0, 10 * v1, 10 * v2, 10 * v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
  });

  static const CGFloat kDeviation = 1e-2;

  it(@"should correctly compute whether a quad is affinely transformable to another quad", ^{
    LTQuad *secondQuad = [quad copyWithTranslation:CGPointMake(7, 8)];
    expect([quad isTransformableToQuad:secondQuad withDeviation:kDeviation
                           translation:&translation rotation:&rotation
                               scaling:&scaling]).to.beTruthy();
    expect(translation).to.beCloseToPointWithin(CGPointMake(7, 8), kEpsilon);
    expect(rotation).to.beCloseToWithin(0, kEpsilon);
    expect(scaling).to.beCloseToWithin(1, kEpsilon);

    secondQuad = [quad copyWithRotation:M_PI_2 aroundPoint:CGPointZero];
    expect([quad isTransformableToQuad:secondQuad withDeviation:kDeviation
                           translation:&translation rotation:&rotation
                               scaling:&scaling]).to.beTruthy();
    expect(translation).to.beCloseToPointWithin(CGPointMake(-9.75000023, 0.25000006), kEpsilon);
    expect(rotation).to.beCloseToWithin(M_PI_2, kEpsilon);
    expect(scaling).to.beCloseToWithin(1, kEpsilon);

    secondQuad = [quad copyWithScaling:2];
    expect([quad isTransformableToQuad:secondQuad withDeviation:kDeviation
                           translation:&translation rotation:&rotation
                               scaling:&scaling]).to.beTruthy();
    expect(translation).to.beCloseToPointWithin(CGPointZero, kEpsilon);
    expect(rotation).to.beCloseToWithin(0, kEpsilon);
    expect(scaling).to.beCloseToWithin(2, kEpsilon);

    LTQuadCorners corners{{v0, v1, w0, v3}};
    secondQuad = [[LTQuad alloc] initWithCorners:corners];
    expect([quad isTransformableToQuad:secondQuad withDeviation:kDeviation
                           translation:&translation rotation:&rotation
                               scaling:&scaling]).to.beFalsy();

    secondQuad = [quad copyWithTranslation:CGPointMake(7, 8)];
    secondQuad = [secondQuad copyWithRotation:M_PI_4 aroundPoint:CGPointZero];
    secondQuad = [secondQuad copyWithScaling:2];
    expect([quad isTransformableToQuad:secondQuad withDeviation:kDeviation
                           translation:&translation rotation:&rotation
                               scaling:&scaling]).to.beTruthy();
    LTQuad *testQuad = [quad copyWithTranslation:translation];
    testQuad = [testQuad copyWithRotation:rotation aroundPoint:testQuad.center];
    testQuad = [testQuad copyWithScaling:scaling];
    expect([secondQuad isSimilarTo:testQuad upToDeviation:kDeviation]).to.beTruthy();
  });
});

context(@"copying", ^{
  beforeEach(^{
    LTQuadCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
  });

  it(@"should create copy", ^{
    LTQuad *copiedQuad = [quad copy];
    expect(copiedQuad).notTo.beIdenticalTo(quad);
    expect(copiedQuad.v0).to.equal(quad.v0);
    expect(copiedQuad.v1).to.equal(quad.v1);
    expect(copiedQuad.v2).to.equal(quad.v2);
    expect(copiedQuad.v3).to.equal(quad.v3);
  });

  it(@"should create copy with given corners", ^{
    LTQuadCorners corners{{v0, v1, w0, v2}};
    LTQuad *result = [quad copyWithCorners:corners];
    expect(result).notTo.beIdenticalTo(quad);
    expect(result.v0).to.equal(v0);
    expect(result.v1).to.equal(v1);
    expect(result.v2).to.equal(w0);
    expect(result.v3).to.equal(v2);
  });

  it(@"should raise when trying to create copy with invalid corners", ^{
    LTQuadCorners corners{{v0, v0, v0, v0}};
    expect(^{
      [quad copyWithCorners:corners];
    }).to.raise(NSInvalidArgumentException);
  });

  context(@"affine transformations", ^{
    it(@"should create copy with rotated corners", ^{
      LTQuadCorners corners{{v0, v1, v2, v3}};
      quad = [[[LTQuad alloc] initWithCorners:corners] copyWithRotation:13.7 / 180.0 * M_PI
                                                            aroundPoint:CGPointMake(3, 1)];
      expect(quad.v0).to.beCloseToPointWithin(CGPointMake(0.322191, -0.682064), kEpsilon);
      expect(quad.v1).to.beCloseToPointWithin(CGPointMake(1.29374, -0.445225), kEpsilon);
      expect(quad.v2).to.beCloseToPointWithin(CGPointMake(1.08059, 0.429169), kEpsilon);
      expect(quad.v3).to.beCloseToPointWithin(CGPointMake(0.0853527, 0.289486), kEpsilon);
      expect(CGPointDistance(quad.v0, quad.v1)).to.beCloseToWithin(CGPointDistance(v0, v1),
                                                                   kEpsilon);
      expect(CGPointDistance(quad.v1, quad.v2)).to.beCloseToWithin(CGPointDistance(v1, v2),
                                                                   kEpsilon);
      expect(CGPointDistance(quad.v2, quad.v3)).to.beCloseToWithin(CGPointDistance(v2, v3),
                                                                   kEpsilon);
      expect(CGPointDistance(quad.v3, quad.v0)).to.beCloseToWithin(CGPointDistance(v3, v0),
                                                                   kEpsilon);
    });

    it(@"should create copy with scaled corners", ^{
      quad = [[LTQuad quadFromRect:CGRectMake(0, 0, 1, 1)] copyWithScaling:2];
      expect(quad.v0).to.beCloseToPoint(CGPointMake(-0.5, -0.5));
      expect(quad.v1).to.beCloseToPoint(CGPointMake(1.5, -0.5));
      expect(quad.v2).to.beCloseToPoint(CGPointMake(1.5, 1.5));
      expect(quad.v3).to.beCloseToPoint(CGPointMake(-0.5, 1.5));
    });

    it(@"should return nil when trying to create copy with invalid scaling", ^{
      expect([[LTQuad quadFromRect:CGRectMake(0, 0, 1, 1)] copyWithScaling:0]).to.beNil();
    });

    it(@"should create copy with corners scaled around an anchor point", ^{
      quad = [[LTQuad quadFromRect:CGRectMake(0, 0, 1, 1)] copyWithScaling:2
                                                               aroundPoint:CGPointZero];
      expect(quad.v0).to.beCloseToPoint(CGPointZero);
      expect(quad.v1).to.beCloseToPoint(CGPointMake(2, 0));
      expect(quad.v2).to.beCloseToPoint(CGPointMake(2, 2));
      expect(quad.v3).to.beCloseToPoint(CGPointMake(0, 2));

      quad = [[LTQuad quadFromRect:CGRectMake(0, 0, 1, 1)] copyWithScaling:2
                                                               aroundPoint:CGPointMake(0.5, 0.5)];
      expect(quad.v0).to.beCloseToPoint(CGPointMake(-0.5, -0.5));
      expect(quad.v1).to.beCloseToPoint(CGPointMake(1.5, -0.5));
      expect(quad.v2).to.beCloseToPoint(CGPointMake(1.5, 1.5));
      expect(quad.v3).to.beCloseToPoint(CGPointMake(-0.5, 1.5));

      quad = [[LTQuad quadFromRect:CGRectMake(0, 0, 1, 1)] copyWithScaling:2
                                                               aroundPoint:CGPointMake(0.5, 0)];
      expect(quad.v0).to.beCloseToPoint(CGPointMake(-0.5, 0));
      expect(quad.v1).to.beCloseToPoint(CGPointMake(1.5, 0));
      expect(quad.v2).to.beCloseToPoint(CGPointMake(1.5, 2));
      expect(quad.v3).to.beCloseToPoint(CGPointMake(-0.5, 2));
    });

    it(@"should return nil when trying to create copy with invalid scaling around anchor point", ^{
      expect([[LTQuad quadFromRect:CGRectMake(0, 0, 1, 1)] copyWithScaling:0
                                                               aroundPoint:CGPointZero]).to.beNil();
    });

    it(@"should create copy with translated corners", ^{
      CGPoint translation = CGPointMake(2, 5);
      LTQuadCorners corners{{v0, v1, v2, v3}};
      quad = [[[LTQuad alloc] initWithCorners:corners] copyWithTranslation:translation
                                                                 ofCorners:LTQuadCornerRegionAll];
      expect(quad.v0).to.beCloseToPoint(v0 + translation);
      expect(quad.v1).to.beCloseToPoint(v1 + translation);
      expect(quad.v2).to.beCloseToPoint(v2 + translation);
      expect(quad.v3).to.beCloseToPoint(v3 + translation);

      quad = [[[LTQuad alloc] initWithCorners:corners] copyWithTranslation:translation
                                                                 ofCorners:LTQuadCornerRegionV1];
      expect(quad.v0).to.beCloseToPoint(v0);
      expect(quad.v1).to.beCloseToPoint(v1 + translation);
      expect(quad.v2).to.beCloseToPoint(v2);
      expect(quad.v3).to.beCloseToPoint(v3);

      quad = [[[LTQuad alloc] initWithCorners:corners] copyWithTranslation:translation
                                                                 ofCorners:LTQuadCornerRegionV2];
      expect(quad.v0).to.beCloseToPoint(v0);
      expect(quad.v1).to.beCloseToPoint(v1);
      expect(quad.v2).to.beCloseToPoint(v2 + translation);
      expect(quad.v3).to.beCloseToPoint(v3);
    });

    it(@"should return nil when trying to create copy with invalid translated corners", ^{
      LTQuadCorners corners{{CGPointZero, CGPointMake(0, 1), CGPointMake(0, 2),
        CGPointMake(-1, 1.5)
      }};
      quad = [[LTQuad alloc] initWithCorners:corners];
      expect([quad copyWithTranslation:CGPointMake(1, 0)
                             ofCorners:LTQuadCornerRegionV3]).to.beNil();
    });

    it(@"should create translated copy", ^{
      CGPoint translation = CGPointMake(2, 5);
      quad = [quad copyWithTranslation:translation];
      expect(quad.v0).to.beCloseToPoint(v0 + translation);
      expect(quad.v1).to.beCloseToPoint(v1 + translation);
      expect(quad.v2).to.beCloseToPoint(v2 + translation);
      expect(quad.v3).to.beCloseToPoint(v3 + translation);
    });
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
  context(@"area", ^{
    it(@"should correctly compute the area of a square quad", ^{
      quad = [LTQuad quadFromRect:CGRectFromSize(CGSizeMakeUniform(1))];
      expect(quad.area).to.beCloseToWithin(1, kEpsilon);
    });

    it(@"should correctly compute the area of a rectangular quad", ^{
      quad = [LTQuad quadFromRect:CGRectFromSize(CGSizeMake(1, 2))];
      expect(quad.area).to.beCloseToWithin(2, kEpsilon);
    });

    it(@"should correctly compute the area of a convex quad", ^{
      LTQuadCorners cornersOfConvexQuad{{v0, v1, CGPointMake(0.75, 0.75), v3}};
      quad = [[LTQuad alloc] initWithCorners:cornersOfConvexQuad];
      expect(quad.area).to.beCloseToWithin(0.75, kEpsilon);
    });

    it(@"should correctly compute the area of a concave quad", ^{
      LTQuadCorners cornersOfConcaveQuad{{v0, v1, CGPointMake(0.25, 0.25), v3}};
      quad = [[LTQuad alloc] initWithCorners:cornersOfConcaveQuad];
      expect(quad.area).to.beCloseToWithin(0.25, kEpsilon);
    });

    it(@"should correctly compute the area of a complex quad", ^{
      LTQuadCorners cornersOfComplexQuad{{v0, v1, v3, CGPointMake(1, 1)}};
      quad = [[LTQuad alloc] initWithCorners:cornersOfComplexQuad];
      expect(quad.area).to.beCloseToWithin(0.5, kEpsilon);
    });
  });

  it(@"should correctly compute the bounding rect", ^{
    LTQuadCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    CGRect expectedBoundingRect = CGRectMake(v0.x, v0.y, v1.x, v3.y);
    expect(quad.boundingRect).to.equal(expectedBoundingRect);
  });

  it(@"should correctly compute its convex hull", ^{
    LTQuadCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    std::vector<CGPoint> convexHull = quad.convexHull;
    expect(convexHull.size()).to.equal(4);
    expect(convexHull[0]).to.equal(v0);
    expect(convexHull[1]).to.equal(v3);
    expect(convexHull[2]).to.equal(v2);
    expect(convexHull[3]).to.equal(v1);

    corners = {{v0, v1, w0, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    convexHull = quad.convexHull;
    expect(convexHull.size()).to.equal(3);
    expect(convexHull[0]).to.equal(v0);
    expect(convexHull[1]).to.equal(v3);
    expect(convexHull[2]).to.equal(v1);
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
      expect($(LTMatFromGLKMatrix3(LTTransformationForQuad(quad.quad)))).to.
          beCloseToMatWithin($(identity), kEpsilon);
    });

    it(@"should provide the correct transformation for non-axis-aligned quads", ^{
      // In iOS, negative values mean clockwise rotation, while positive values in OSX.
#if TARGET_OS_SIMULATOR || TARGET_OS_IPHONE
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
      expect($(LTMatFromGLKMatrix3(quad.transform))).to.
          beCloseToMatWithin($(LTMatFromGLKMatrix3(expectedTransform)), kEpsilon);
      expect($(LTMatFromGLKMatrix3(LTTransformationForQuad(quad.quad)))).to.
          beCloseToMatWithin($(LTMatFromGLKMatrix3(expectedTransform)), kEpsilon);

      LTQuadCorners corners1{{CGPointMake(5.1, -2.7),
                              CGPointMake(19.2, 22.2),
                              CGPointMake(44.34, 190.2),
                              CGPointMake(-29.132, 99.1)}};
      quad = [[LTQuad alloc] initWithCorners:corners1];
      expect($(LTMatFromGLKMatrix3(quad.transform))).to.
          beCloseToMatWithin($(LTMatFromGLKMatrix3(LTTransformationForQuad(quad.quad))), kEpsilon);
    });
  });

  it(@"should correctly compute the minimum edge length", ^{
    LTQuadCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    expect(quad.minimalEdgeLength).to.beCloseToWithin(0.8999999761581421, kEpsilon);

    corners = LTQuadCorners{{v0, v1, w0, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    expect(quad.minimalEdgeLength).to.beCloseToWithin(0.7905694246292114, kEpsilon);
  });

  it(@"should correctly compute the minimum edge length", ^{
    LTQuadCorners corners{{v0, v1, v2, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    expect(quad.maximalEdgeLength).to.beCloseToWithin(1.0049875, kEpsilon);

    corners = LTQuadCorners{{v0, v1, w0, v3}};
    quad = [[LTQuad alloc] initWithCorners:corners];
    expect(quad.maximalEdgeLength).to.beCloseToWithin(1, kEpsilon);
  });
});

SpecEnd

SpecBegin(LT_Quad)

__block CGPoint v0;
__block CGPoint v1;
__block CGPoint v2;
__block CGPoint v3;
__block CGPoint w0;

beforeAll(^{
  v0 = CGPointMake(0, 0);
  v1 = CGPointMake(1, 0);
  v2 = CGPointMake(1, 0.9);
  v3 = CGPointMake(0, 1);
  w0 = CGPointMake(0.25, 0.25);
});

context(@"initialization", ^{
  it(@"should default initialize to the null quad", ^{
    lt::Quad quad;
    expect(CGPointIsNull(quad.v0())).to.beTruthy();
    expect(CGPointIsNull(quad.v1())).to.beTruthy();
    expect(CGPointIsNull(quad.v2())).to.beTruthy();
    expect(CGPointIsNull(quad.v3())).to.beTruthy();
  });

  it(@"should initialize with corners", ^{
    lt::Quad quad(v0, v1, v2, v3);
    expect(quad.v0()).to.equal(v0);
    expect(quad.v1()).to.equal(v1);
    expect(quad.v2()).to.equal(v2);
    expect(quad.v3()).to.equal(v3);
  });

  it(@"should initialize with corner array", ^{
    lt::Quad::Corners corners = {{v0, v1, v2, v3}};
    lt::Quad quad(corners);
    expect(quad.v0()).to.equal(v0);
    expect(quad.v1()).to.equal(v1);
    expect(quad.v2()).to.equal(v2);
    expect(quad.v3()).to.equal(v3);
  });

  it(@"should initialize with rect", ^{
    lt::Quad quad(CGRectFromSize(CGSizeMakeUniform(1)));
    expect(quad.v0()).to.equal(CGPointZero);
    expect(quad.v1()).to.equal(CGPointMake(1, 0));
    expect(quad.v2()).to.equal(CGPointMake(1, 1));
    expect(quad.v3()).to.equal(CGPointMake(0, 1));
  });
});

context(@"point inclusion", ^{
  it(@"should correctly compute point inclusion for the null quad", ^{
    expect(lt::Quad().containsPoint(CGPointZero)).to.beFalsy();
  });

  it(@"should correctly compute point inclusion for quads with triangle shape", ^{
    lt::Quad quad(CGPointZero, CGPointZero, CGPointMake(1, 0), CGPointMake(1, 1));
    expect(quad.containsPoint(CGPointZero)).to.beTruthy();
    expect(quad.containsPoint(CGPointMake(0.5, 0.5))).to.beTruthy();
    expect(quad.containsPoint(CGPointMake(2, 2))).to.beFalsy();
  });

  context(@"degenerate quads", ^{
    it(@"should return NO upon inclusion queries for point quads", ^{
      CGPoint point = CGPointMake(7, 8.5);
      lt::Quad::Corners corners{{point, point, point, point}};
      lt::Quad quad(corners);
      expect(quad.containsPoint(point)).to.beFalsy();
      expect(quad.containsPoint(CGPointZero)).to.beFalsy();
    });

    it(@"should return NO upon inclusion queries for quads with exclusively collinear corners", ^{
      lt::Quad::Corners corners{{CGPointZero, CGPointMake(1, 1), CGPointMake(2, 2),
        CGPointMake(3, 3)}};
      lt::Quad quad(corners);
      expect(quad.containsPoint(CGPointMake(0.5, 0.5))).to.beFalsy();
      expect(quad.containsPoint(CGPointMake(0.5, 0))).to.beFalsy();
    });
  });

  context(@"convex quads", ^{
    it(@"should compute point inclusion for quads with corners in clockwise direction", ^{
      lt::Quad::Corners corners{{v0, v1, v2, v3}};
      lt::Quad quad(corners);
      expect(quad.containsPoint(v0)).to.beTruthy();
      expect(quad.containsPoint((v0 + v1) / 2)).to.beTruthy();
      expect(quad.containsPoint(v1)).to.beTruthy();
      expect(quad.containsPoint(v2)).to.beTruthy();
      expect(quad.containsPoint(v3)).to.beTruthy();
      expect(quad.containsPoint(w0)).to.beTruthy();
      expect(quad.containsPoint(CGPointMake(-1, -1))).to.beFalsy();
      expect(quad.containsPoint(CGPointMake(0, -1))).to.beFalsy();
      expect(quad.containsPoint(CGPointMake(1, 1))).to.beFalsy();
    });

    it(@"should compute point inclusion for quads with corners in anti-clockwise direction", ^{
      lt::Quad::Corners corners{{v3, v2, v1, v0}};
      lt::Quad quad(corners);
      expect(quad.containsPoint(v0)).to.beTruthy();
      expect(quad.containsPoint((v0 + v1) / 2)).to.beTruthy();
      expect(quad.containsPoint(v1)).to.beTruthy();
      expect(quad.containsPoint(v2)).to.beTruthy();
      expect(quad.containsPoint(v3)).to.beTruthy();
      expect(quad.containsPoint(w0)).to.beTruthy();
      expect(quad.containsPoint(CGPointMake(-1, -1))).to.beFalsy();
      expect(quad.containsPoint(CGPointMake(0, -1))).to.beFalsy();
      expect(quad.containsPoint(CGPointMake(1, 1))).to.beFalsy();
    });
  });

  context(@"concave quads", ^{
    it(@"should compute point inclusion for quads with corners in clockwise direction", ^{
      lt::Quad::Corners corners{{v0, v1, w0, v3}};
      lt::Quad quad(corners);
      expect(quad.containsPoint(v0)).to.beTruthy();
      expect(quad.containsPoint((v0 + v1) / 2)).to.beTruthy();
      expect(quad.containsPoint(v1)).to.beTruthy();
      expect(quad.containsPoint(w0)).to.beTruthy();
      expect(quad.containsPoint(v2)).to.beFalsy();
      expect(quad.containsPoint((v0 + w0) / 2)).to.beTruthy();
      expect(quad.containsPoint(CGPointMake(-1, -1))).to.beFalsy();
      expect(quad.containsPoint(CGPointMake(0, -1))).to.beFalsy();
      expect(quad.containsPoint(CGPointMake(1, 1))).to.beFalsy();
    });

    it(@"should compute point inclusion for quads with corners in anti-clockwise direction", ^{
      lt::Quad::Corners corners{{v3, w0, v1, v0}};
      lt::Quad quad(corners);
      expect(quad.containsPoint(v0)).to.beTruthy();
      expect(quad.containsPoint((v0 + v1) / 2)).to.beTruthy();
      expect(quad.containsPoint(v1)).to.beTruthy();
      expect(quad.containsPoint(w0)).to.beTruthy();
      expect(quad.containsPoint(v2)).to.beFalsy();
      expect(quad.containsPoint((v0 + w0) / 2)).to.beTruthy();
      expect(quad.containsPoint(CGPointMake(-1, -1))).to.beFalsy();
      expect(quad.containsPoint(CGPointMake(0, -1))).to.beFalsy();
      expect(quad.containsPoint(CGPointMake(1, 1))).to.beFalsy();
    });
  });

  context(@"complex quads", ^{
    it(@"should correctly compute point inclusion for a complex quad", ^{
      lt::Quad::Corners corners{{v0, v1, v3, v2}};
      lt::Quad quad(corners);
      expect(quad.containsPoint(v0)).to.beTruthy();
      expect(quad.containsPoint((v0 + v1) / 2)).to.beTruthy();
      expect(quad.containsPoint(v1)).to.beTruthy();
      expect(quad.containsPoint(v2)).to.beTruthy();
      expect(quad.containsPoint(v3)).to.beTruthy();
      expect(quad.containsPoint(w0)).to.beFalsy();
      expect(quad.containsPoint((v0 + v3) / 2)).to.beFalsy();
      expect(quad.containsPoint(CGPointMake(0.25, 0.1))).to.beTruthy();
      expect(quad.containsPoint(CGPointMake(-1, -1))).to.beFalsy();
      expect(quad.containsPoint(CGPointMake(0, -1))).to.beFalsy();
      expect(quad.containsPoint(CGPointMake(1, 1))).to.beFalsy();
    });
  });
});

context(@"vertex inclusion", ^{
  it(@"should correctly compute vertex inclusion for a convex quad", ^{
    lt::Quad::Corners corners{{v0, v1, v3, v2}};
    lt::Quad quad(corners);
    lt::Quad anotherQuad(CGRectMake(-1, -1, 1, 1));
    expect(quad.containsVertexOfQuad(anotherQuad)).to.beTruthy();
    anotherQuad = lt::Quad(CGRectMake(0.5, 0.5, 0.2, 0.2));
    expect(quad.containsVertexOfQuad(anotherQuad)).to.beTruthy();
    anotherQuad = lt::Quad(CGRectMake(-1, -1, 0.5, 0.5));
    expect(quad.containsVertexOfQuad(anotherQuad)).to.beFalsy();
    anotherQuad = lt::Quad(CGRectMake(-1, -1, 2, 2));
    expect(quad.containsVertexOfQuad(anotherQuad)).to.beFalsy();
  });

  it(@"should correctly compute vertex inclusion for a complex quad", ^{
    lt::Quad::Corners corners = {{v0, v1, w0, v2}};
    lt::Quad quad = lt::Quad(corners);
    lt::Quad anotherQuad(CGRectMake(-1, -1, 1, 1));
    expect(quad.containsVertexOfQuad(anotherQuad)).to.beTruthy();
    anotherQuad = lt::Quad(CGRectMake(-0.1, -0.2, 0.3, 0.3));
    expect(quad.containsVertexOfQuad(anotherQuad)).to.beTruthy();
    anotherQuad = lt::Quad(CGRectMake(0.1, -0.5, 10, 1));
    expect(quad.containsVertexOfQuad(anotherQuad)).to.beFalsy();
    anotherQuad = lt::Quad(CGRectMake(-1, -1, 3, 3));
    expect(quad.containsVertexOfQuad(anotherQuad)).to.beFalsy();
  });
});

context(@"closest point computation", ^{
  it(@"should correctly compute the closest point on any of its edges from a given point", ^{
    lt::Quad quad = lt::Quad::canonicalSquare();
    CGPoint point = CGPointMake(-0.5, -0.5);
    expect(quad.pointOnEdgeClosestToPoint(point)).to.beCloseToPointWithin(quad.v0(), kEpsilon);

    point = CGPointMake(0.75, -0.5);
    expect(quad.pointOnEdgeClosestToPoint(point)).to.beCloseToPointWithin(CGPointMake(0.75, 0),
                                                                          kEpsilon);

    point = CGPointMake(1.5, -0.5);
    expect(quad.pointOnEdgeClosestToPoint(point)).to.beCloseToPointWithin(quad.v1(), kEpsilon);

    point = CGPointMake(0.9, 0.1);
    expect(quad.pointOnEdgeClosestToPoint(point)).to.beCloseToPointWithin(CGPointMake(0.9, 0),
                                                                          kEpsilon);

    point = CGPointMake(100, 1);
    expect(quad.pointOnEdgeClosestToPoint(point)).to.beCloseToPointWithin(quad.v2(), kEpsilon);

    point = CGPointMake(-0.4, 1);
    expect(quad.pointOnEdgeClosestToPoint(point)).to.beCloseToPointWithin(quad.v3(), kEpsilon);
  });

  it(@"should correctly compute the points with minimum distance located on edges of two quads", ^{
    lt::Quad quad = lt::Quad::canonicalSquare();
    lt::Quad anotherQuad(CGRectMake(0.5, 1.5, 1, 1));
    CGPointPair result = quad.nearestPoints(anotherQuad);
    expect(result.first).to.beCloseToPointWithin(CGPointMake(1, 1), kEpsilon);
    expect(result.second).to.beCloseToPointWithin(CGPointMake(1, 1.5), kEpsilon);

    lt::Quad::Corners corners{{CGPointZero, CGPointMake(1, 0), CGPointMake(1.5, 0.5),
      CGPointMake(1.5, 1)}};
    quad = lt::Quad(corners);
    anotherQuad = lt::Quad(CGRectMake(0, 2, 1, 1));
    result = quad.nearestPoints(anotherQuad);
    expect(result.first).to.beCloseToPointWithin(quad.v3(), kEpsilon);
    expect(result.second).to.beCloseToPointWithin(anotherQuad.v1(), kEpsilon);

    anotherQuad = lt::Quad(CGRectMake(-0.5, -0.5, 1, 1));
    result = quad.nearestPoints(anotherQuad);
    expect(result.first).to.beCloseToPointWithin(CGPointMake(0.5, 0), kEpsilon);
    expect(result.second).to.beCloseToPointWithin(CGPointMake(0.5, 0), kEpsilon);
  });
});

context(@"transformations", ^{
  context(@"affine transformations", ^{
    context(@"rotation", ^{
      __block lt::Quad quad;
      __block CGFloat angle;

      beforeEach(^{
        quad = lt::Quad::canonicalSquare();
        angle = M_PI;
      });

      it(@"should create a copy with corners rotated around the quad center", ^{
        lt::Quad rotatedQuad = quad.rotatedAroundPoint(angle, quad.center());
        expect(rotatedQuad.v0()).to.beCloseToPointWithin(quad.v2(), kEpsilon);
        expect(rotatedQuad.v1()).to.beCloseToPointWithin(quad.v3(), kEpsilon);
        expect(rotatedQuad.v2()).to.beCloseToPointWithin(quad.v0(), kEpsilon);
        expect(rotatedQuad.v3()).to.beCloseToPointWithin(quad.v1(), kEpsilon);
      });

      it(@"should create a copy with corners rotated around an anchor point", ^{
        lt::Quad rotatedQuad = quad.rotatedAroundPoint(angle, CGPointZero);
        expect(rotatedQuad.v0()).to.beCloseToPointWithin(CGPointZero, kEpsilon);
        expect(rotatedQuad.v1()).to.beCloseToPointWithin(CGPointMake(-1, 0), kEpsilon);
        expect(rotatedQuad.v2()).to.beCloseToPointWithin(CGPointMake(-1, -1), kEpsilon);
        expect(rotatedQuad.v3()).to.beCloseToPointWithin(CGPointMake(0, -1), kEpsilon);
      });
    });

    context(@"scaling", ^{
      __block lt::Quad quad;
      __block CGFloat scaleFactor;

      beforeEach(^{
        quad = lt::Quad::canonicalSquare();
        scaleFactor = 2;
      });

      context(@"uniform scaling", ^{
        it(@"should create a scaled copy", ^{
          lt::Quad scaledQuad = quad.scaledBy(scaleFactor);
          expect(scaledQuad.v0()).to.equal(CGPointMake(-0.5, -0.5));
          expect(scaledQuad.v1()).to.equal(CGPointMake(1.5, -0.5));
          expect(scaledQuad.v2()).to.equal(CGPointMake(1.5, 1.5));
          expect(scaledQuad.v3()).to.equal(CGPointMake(-0.5, 1.5));
        });

        it(@"should create a copy with corners scaled around the origin", ^{
          lt::Quad scaledQuad = quad.scaledAround(scaleFactor, CGPointZero);
          expect(scaledQuad.v0()).to.equal(CGPointZero);
          expect(scaledQuad.v1()).to.equal(CGPointMake(2, 0));
          expect(scaledQuad.v2()).to.equal(CGPointMake(2, 2));
          expect(scaledQuad.v3()).to.equal(CGPointMake(0, 2));
        });

        it(@"should create a copy with corners scaled around the quad center", ^{
          lt::Quad scaledQuad = quad.scaledAround(scaleFactor, CGPointMake(0.5, 0.5));
          expect(scaledQuad.v0()).to.equal(CGPointMake(-0.5, -0.5));
          expect(scaledQuad.v1()).to.equal(CGPointMake(1.5, -0.5));
          expect(scaledQuad.v2()).to.equal(CGPointMake(1.5, 1.5));
          expect(scaledQuad.v3()).to.equal(CGPointMake(-0.5, 1.5));
        });

        it(@"should create a copy with corners scaled around an anchor point", ^{
          lt::Quad scaledQuad = quad.scaledAround(scaleFactor, CGPointMake(0.5, 0));
          expect(scaledQuad.v0()).to.equal(CGPointMake(-0.5, 0));
          expect(scaledQuad.v1()).to.equal(CGPointMake(1.5, 0));
          expect(scaledQuad.v2()).to.equal(CGPointMake(1.5, 2));
          expect(scaledQuad.v3()).to.equal(CGPointMake(-0.5, 2));
        });

        it(@"should create a zero quad when scaling with factor of 0 around the quad center", ^{
          CGPoint center = quad.center();
          lt::Quad scaledQuad = quad.scaledBy(0);
          expect(scaledQuad.v0()).to.equal(center);
          expect(scaledQuad.v1()).to.equal(center);
          expect(scaledQuad.v2()).to.equal(center);
          expect(scaledQuad.v3()).to.equal(center);
        });

        it(@"should create a point quad when scaling with factor of 0 around an anchor point", ^{
          CGPoint point = CGPointMake(1, 1);
          lt::Quad scaledQuad = quad.scaledAround(0, point);
          expect(scaledQuad.v0()).to.equal(point);
          expect(scaledQuad.v1()).to.equal(point);
          expect(scaledQuad.v2()).to.equal(point);
          expect(scaledQuad.v3()).to.equal(point);
        });
      });

      context(@"non-uniform scaling", ^{
        __block CGFloat verticalScaleFactor;

        beforeEach(^{
          verticalScaleFactor = 0.5;
        });

        it(@"should create a scaled copy", ^{
          lt::Quad scaledQuad = quad.scaledBy(LTVector2(scaleFactor, verticalScaleFactor));
          expect(scaledQuad.v0()).to.equal(CGPointMake(-0.5, 0.25));
          expect(scaledQuad.v1()).to.equal(CGPointMake(1.5, 0.25));
          expect(scaledQuad.v2()).to.equal(CGPointMake(1.5, 0.75));
          expect(scaledQuad.v3()).to.equal(CGPointMake(-0.5, 0.75));
        });

        it(@"should create a copy with corners scaled around the origin", ^{
          lt::Quad scaledQuad = quad.scaledAround(LTVector2(scaleFactor, verticalScaleFactor),
                                                  CGPointZero);
          expect(scaledQuad.v0()).to.equal(CGPointZero);
          expect(scaledQuad.v1()).to.equal(CGPointMake(2, 0));
          expect(scaledQuad.v2()).to.equal(CGPointMake(2, 0.5));
          expect(scaledQuad.v3()).to.equal(CGPointMake(0, 0.5));
        });

        it(@"should create a copy with corners scaled around the quad center", ^{
          lt::Quad scaledQuad = quad.scaledAround(LTVector2(scaleFactor, verticalScaleFactor),
                                                  CGPointMake(0.5, 0.5));
          expect(scaledQuad.v0()).to.equal(CGPointMake(-0.5, 0.25));
          expect(scaledQuad.v1()).to.equal(CGPointMake(1.5, 0.25));
          expect(scaledQuad.v2()).to.equal(CGPointMake(1.5, 0.75));
          expect(scaledQuad.v3()).to.equal(CGPointMake(-0.5, 0.75));
        });

        it(@"should create a copy with corners scaled around an anchor point", ^{
          lt::Quad scaledQuad = quad.scaledAround(LTVector2(scaleFactor, verticalScaleFactor),
                                                  CGPointMake(0.5, 0));
          expect(scaledQuad.v0()).to.equal(CGPointMake(-0.5, 0));
          expect(scaledQuad.v1()).to.equal(CGPointMake(1.5, 0));
          expect(scaledQuad.v2()).to.equal(CGPointMake(1.5, 0.5));
          expect(scaledQuad.v3()).to.equal(CGPointMake(-0.5, 0.5));
        });
      });
    });

    context(@"translation", ^{
      __block lt::Quad quad;
      __block CGPoint translation;

      beforeEach(^{
        translation = CGPointMake(2, 5);
      });

      context(@"non-null quads", ^{
        beforeEach(^{
          lt::Quad::Corners corners{{v0, v1, v2, v3}};
          quad = lt::Quad(corners);
        });

        it(@"should create a translated copy", ^{
          lt::Quad translatedQuad = quad.translatedBy(translation);
          expect(translatedQuad.v0()).to.beCloseToPoint(v0 + translation);
          expect(translatedQuad.v1()).to.beCloseToPoint(v1 + translation);
          expect(translatedQuad.v2()).to.beCloseToPoint(v2 + translation);
          expect(translatedQuad.v3()).to.beCloseToPoint(v3 + translation);
        });

        it(@"should create a copy with all corners being translated", ^{
          lt::Quad translatedQuad = quad.translatedBy(translation, LTQuadCornerRegionAll);
          expect(translatedQuad.v0()).to.beCloseToPoint(v0 + translation);
          expect(translatedQuad.v1()).to.beCloseToPoint(v1 + translation);
          expect(translatedQuad.v2()).to.beCloseToPoint(v2 + translation);
          expect(translatedQuad.v3()).to.beCloseToPoint(v3 + translation);
        });

        it(@"should create a copy with first corner being translated", ^{
          lt::Quad translatedQuad = quad.translatedBy(translation, LTQuadCornerRegionV0);
          expect(translatedQuad.v0()).to.beCloseToPoint(v0 + translation);
          expect(translatedQuad.v1()).to.beCloseToPoint(v1);
          expect(translatedQuad.v2()).to.beCloseToPoint(v2);
          expect(translatedQuad.v3()).to.beCloseToPoint(v3);
        });

        it(@"should create a copy with second corner being translated", ^{
          lt::Quad translatedQuad = quad.translatedBy(translation, LTQuadCornerRegionV1);
          expect(translatedQuad.v0()).to.beCloseToPoint(v0);
          expect(translatedQuad.v1()).to.beCloseToPoint(v1 + translation);
          expect(translatedQuad.v2()).to.beCloseToPoint(v2);
          expect(translatedQuad.v3()).to.beCloseToPoint(v3);
        });

        it(@"should create a copy with third corner being translated", ^{
          lt::Quad translatedQuad = quad.translatedBy(translation, LTQuadCornerRegionV2);
          expect(translatedQuad.v0()).to.beCloseToPoint(v0);
          expect(translatedQuad.v1()).to.beCloseToPoint(v1);
          expect(translatedQuad.v2()).to.beCloseToPoint(v2 + translation);
          expect(translatedQuad.v3()).to.beCloseToPoint(v3);
        });

        it(@"should create a copy with fourth corner being translated", ^{
          lt::Quad translatedQuad = quad.translatedBy(translation, LTQuadCornerRegionV3);
          expect(translatedQuad.v0()).to.beCloseToPoint(v0);
          expect(translatedQuad.v1()).to.beCloseToPoint(v1);
          expect(translatedQuad.v2()).to.beCloseToPoint(v2);
          expect(translatedQuad.v3()).to.beCloseToPoint(v3 + translation);
        });

        it(@"should create a copy with several corners being translated", ^{
          lt::Quad translatedQuad = quad.translatedBy(translation,
                                                      LTQuadCornerRegionV1 | LTQuadCornerRegionV2);
          expect(translatedQuad.v0()).to.beCloseToPoint(v0);
          expect(translatedQuad.v1()).to.beCloseToPoint(v1 + translation);
          expect(translatedQuad.v2()).to.beCloseToPoint(v2 + translation);
          expect(translatedQuad.v3()).to.beCloseToPoint(v3);
        });
      });

      context(@"null quads", ^{
        beforeEach(^{
          lt::Quad::Corners corners{{v0, v1, v2, CGPointNull}};
          quad = lt::Quad(corners);
        });

        it(@"should create a translated copy", ^{
          lt::Quad translatedQuad = quad.translatedBy(translation);
          expect(translatedQuad.v0()).to.beCloseToPoint(v0 + translation);
          expect(translatedQuad.v1()).to.beCloseToPoint(v1 + translation);
          expect(translatedQuad.v2()).to.beCloseToPoint(v2 + translation);
          expect(CGPointIsNull(translatedQuad.v3())).to.beTruthy();
        });
      });
    });

    context(@"affine transformations", ^{
      __block CGPoint translation;
      __block CGAffineTransform transformation;

      beforeEach(^{
        translation = CGPointMake(2, 5);
        transformation = CGAffineTransformConcat(CGAffineTransformMakeTranslation(2, 5),
                                                 CGAffineTransformMakeScale(2, 1));
      });

      it(@"should create copy transformed by CGAffineTransform", ^{
        lt::Quad quad = lt::Quad({{v0, v1, v2, v3}}).transformedBy(transformation);
        expect(quad.v0()).to.beCloseToPoint(CGPointMake(2, 1) * (v0 + translation));
        expect(quad.v1()).to.beCloseToPoint(CGPointMake(2, 1) * (v1 + translation));
        expect(quad.v2()).to.beCloseToPoint(CGPointMake(2, 1) * (v2 + translation));
        expect(quad.v3()).to.beCloseToPoint(CGPointMake(2, 1) * (v3 + translation));
      });

      it(@"should create copy transformed by GLKMatrix3", ^{
        lt::Quad quad =
            lt::Quad({{v0, v1, v2, v3}}).transformedBy(GLKMatrix3WithTransform(transformation));
        expect(quad.v0()).to.beCloseToPointWithin(CGPointMake(2, 1) * (v0 + translation), kEpsilon);
        expect(quad.v1()).to.beCloseToPointWithin(CGPointMake(2, 1) * (v1 + translation), kEpsilon);
        expect(quad.v2()).to.beCloseToPointWithin(CGPointMake(2, 1) * (v2 + translation), kEpsilon);
        expect(quad.v3()).to.beCloseToPointWithin(CGPointMake(2, 1) * (v3 + translation), kEpsilon);
      });
    });

    it(@"should create copy transformed by perspective transformation", ^{
      lt::Quad quad = lt::Quad({{
        CGPointZero,
        CGPointMake(1, 0),
        CGPointMake(20, 35),
        CGPointMake(0, 10)
      }});
      GLKMatrix3 transform = GLKMatrix3Invert(GLKMatrix3Transpose(quad.transform()), NULL);
      lt::Quad transformedQuad = quad.transformedBy(transform);
      expect(transformedQuad.v0()).to.beCloseToPointWithin(CGPointZero, kEpsilon);
      expect(transformedQuad.v1()).to.beCloseToPointWithin(CGPointMake(1, 0), kEpsilon);
      expect(transformedQuad.v2()).to.beCloseToPointWithin(CGPointMake(1, 1), kEpsilon);
      expect(transformedQuad.v3()).to.beCloseToPointWithin(CGPointMake(0, 1), kEpsilon);
    });
  });

  context(@"transformability", ^{
    __block lt::Quad quad;
    __block CGPoint translation;
    __block CGFloat rotation;
    __block CGFloat scaling;

    beforeEach(^{
      lt::Quad::Corners corners{{10 * v0, 10 * v1, 10 * v2, 10 * v3}};
      quad = lt::Quad(corners);
    });

    static const CGFloat kDeviation = 1e-2;

    it(@"should correctly compute whether and how a quad is transformable to another quad", ^{
      lt::Quad secondQuad = quad.translatedBy(CGPointMake(7, 8));
      expect(quad.isTransformableToQuadWithDeviation(secondQuad, kDeviation, &translation,
                                                     &rotation, &scaling)).to.beTruthy();
      expect(translation).to.beCloseToPointWithin(CGPointMake(7, 8), kEpsilon);
      expect(rotation).to.beCloseToWithin(0, kEpsilon);
      expect(scaling).to.beCloseToWithin(1, kEpsilon);

      secondQuad = quad.rotatedAroundPoint(M_PI_2, CGPointZero);
      expect(quad.isTransformableToQuadWithDeviation(secondQuad, kDeviation, &translation,
                                                     &rotation, &scaling)).to.beTruthy();
      expect(translation).to.beCloseToPointWithin(CGPointMake(-9.75000023, 0.25000006), kEpsilon);
      expect(rotation).to.beCloseToWithin(M_PI_2, kEpsilon);
      expect(scaling).to.beCloseToWithin(1, kEpsilon);

      secondQuad = quad.scaledBy(2);
      expect(quad.isTransformableToQuadWithDeviation(secondQuad, kDeviation, &translation,
                                                     &rotation, &scaling)).to.beTruthy();
      expect(translation).to.beCloseToPointWithin(CGPointZero, kEpsilon);
      expect(rotation).to.beCloseToWithin(0, kEpsilon);
      expect(scaling).to.beCloseToWithin(2, kEpsilon);

      translation = CGPointMake(1, 2);
      rotation = 3;
      scaling = 4;
      lt::Quad::Corners corners{{v0, v1, w0, v3}};
      secondQuad = lt::Quad(corners);
      expect(quad.isTransformableToQuadWithDeviation(secondQuad, kDeviation, &translation,
                                                     &rotation, &scaling)).to.beFalsy();
      expect(translation).to.equal(CGPointMake(1, 2));
      expect(rotation).to.equal(3);
      expect(scaling).to.equal(4);

      secondQuad = quad.translatedBy(CGPointMake(7, 8));
      secondQuad = secondQuad.rotatedAroundPoint(M_PI_4, CGPointZero);
      secondQuad = secondQuad.scaledBy(2);
      expect(quad.isTransformableToQuadWithDeviation(secondQuad, kDeviation, &translation,
                                                     &rotation, &scaling)).to.beTruthy();
      lt::Quad testQuad = quad.translatedBy(translation);
      testQuad = testQuad.rotatedAroundPoint(rotation, testQuad.center());
      testQuad = testQuad.scaledBy(scaling);
      expect(secondQuad.isSimilarToQuadUpToDeviation(testQuad, kDeviation)).to.beTruthy();
    });
  });
});

context(@"similarity", ^{
  __block lt::Quad quad0;
  __block lt::Quad quad1;
  __block lt::Quad quad2;

  beforeEach(^{
    lt::Quad::Corners corners{{v0, v1, v2, v3}};
    quad0 = lt::Quad(corners);
    quad1 = lt::Quad(corners);
    corners = lt::Quad::Corners{{v0, v1, v2, v3 + CGPointMake(kEpsilon / 2, 0)}};
    quad2 = lt::Quad(corners);
  });

  it(@"should correctly compute similarity between two quads", ^{
    expect(quad0.isSimilarToQuadUpToDeviation(quad1, kEpsilon)).to.beTruthy();
    expect(quad1.isSimilarToQuadUpToDeviation(quad2, kEpsilon)).to.beTruthy();
    expect(quad2.isSimilarToQuadUpToDeviation(quad0, kEpsilon)).to.beTruthy();

    lt::Quad::Corners corners{{v0, v1, v2, v3 + CGPointMake(kEpsilon, 0)}};
    quad1 = lt::Quad(corners);
    expect(quad0.isSimilarToQuadUpToDeviation(quad1, kEpsilon)).to.beTruthy();

    corners = lt::Quad::Corners{{v0, v1, v2, v3 + CGPointMake(2 * kEpsilon, 0)}};
    quad2 = lt::Quad(corners);
    expect(quad0.isSimilarToQuadUpToDeviation(quad2, kEpsilon)).to.beFalsy();
  });
});

context(@"properties", ^{
  context(@"area", ^{
    it(@"should return NAN as area of a null quad", ^{
      expect(lt::Quad().area()).to.equal(NAN);
    });

    it(@"should correctly compute the area of quads with triangle shape", ^{
      lt::Quad quad(CGPointZero, CGPointZero, CGPointMake(1, 0), CGPointMake(1, 1));
      expect(quad.area()).to.equal(0.5);
    });

    context(@"degenerate quads", ^{
      it(@"should return 0 as area of point quads", ^{
        CGPoint point = CGPointMake(1, 1);
        lt::Quad::Corners corners{{point, point, point, point}};
        expect(lt::Quad(corners).area()).to.equal(0);
      });

      it(@"should return 0 as area of collinear quads", ^{
        lt::Quad::Corners corners{{CGPointZero, CGPointMake(1, 1), CGPointMake(2, 2)}};
        expect(lt::Quad(corners).area()).to.equal(0);
      });
    });

    context(@"convex quads", ^{
      it(@"should correctly compute the area of square quads", ^{
        lt::Quad quad = lt::Quad(CGRectFromSize(CGSizeMakeUniform(1)));
        expect(quad.area()).to.beCloseToWithin(1, kEpsilon);
      });

      it(@"should correctly compute the area of rectangular quads", ^{
        lt::Quad quad = lt::Quad(CGRectFromSize(CGSizeMake(1, 2)));
        expect(quad.area()).to.beCloseToWithin(2, kEpsilon);
      });

      it(@"should correctly compute the area of non-rectangular convex quads", ^{
        lt::Quad::Corners cornersOfConvexQuad{{v0, v1, CGPointMake(0.75, 0.75), v3}};
        lt::Quad quad = lt::Quad(cornersOfConvexQuad);
        expect(quad.area()).to.beCloseToWithin(0.75, kEpsilon);
      });
    });

    it(@"should correctly compute the area of concave quads", ^{
      lt::Quad::Corners cornersOfConcaveQuad{{v0, v1, CGPointMake(0.25, 0.25), v3}};
      lt::Quad quad = lt::Quad(cornersOfConcaveQuad);
      expect(quad.area()).to.beCloseToWithin(0.25, kEpsilon);
    });

    it(@"should correctly compute the area of complex quads", ^{
      lt::Quad::Corners cornersOfComplexQuad{{v0, v1, v3, CGPointMake(1, 1)}};
      lt::Quad quad = lt::Quad(cornersOfComplexQuad);
      expect(quad.area()).to.beCloseToWithin(0.5, kEpsilon);
    });
  });

  it(@"should correctly compute the bounding rect", ^{
    lt::Quad::Corners corners{{v0, v1, v2, v3}};
    lt::Quad quad = lt::Quad(corners);
    CGRect expectedBoundingRect = CGRectMake(v0.x, v0.y, v1.x, v3.y);
    expect(quad.boundingRect()).to.equal(expectedBoundingRect);
  });

  it(@"should return the correct center", ^{
    lt::Quad quad = lt::Quad::canonicalSquare();
    expect(quad.center()).to.equal(CGPointMake(0.5, 0.5));
    lt::Quad::Corners corners{{v0, v1, v2, v3}};
    quad = lt::Quad(corners);
    expect(quad.center()).to.equal((v0 + v1 + v2 + v3) / 4);
  });

  context(@"convex hull", ^{
    it(@"should correctly compute the convex hull of a convex quad", ^{
      lt::Quad::Corners corners{{v0, v1, v2, v3}};
      lt::Quad quad = lt::Quad(corners);
      std::vector<CGPoint> convexHull = quad.convexHull();
      expect(convexHull.size()).to.equal(4);
      expect(convexHull[0]).to.equal(v0);
      expect(convexHull[1]).to.equal(v3);
      expect(convexHull[2]).to.equal(v2);
      expect(convexHull[3]).to.equal(v1);
    });

    it(@"should correctly compute the convex hull of a concave quad", ^{
      lt::Quad::Corners corners = {{v0, v1, w0, v3}};
      lt::Quad quad = lt::Quad(corners);
      std::vector<CGPoint> convexHull = quad.convexHull();
      expect(convexHull.size()).to.equal(3);
      expect(convexHull[0]).to.equal(v0);
      expect(convexHull[1]).to.equal(v3);
      expect(convexHull[2]).to.equal(v1);
    });
  });

  context(@"corners", ^{
    it(@"should return the correct corners", ^{
      lt::Quad::Corners corners{{v0, v1, v2, v3}};
      expect(lt::Quad(corners).corners() == corners).to.beTruthy();
    });
  });

  context(@"hash", ^{
    it(@"should compute a correct hash value", ^{
      lt::Quad::Corners corners{{v0, v1, v2, v3}};
      expect(std::hash<lt::Quad>()(lt::Quad(corners)))
      .to.equal(std::hash<lt::Quad>()(lt::Quad(corners)));
    });
  });

  context(@"null quad", ^{
    it(@"should return YES for calls to isNull() on the default quad", ^{
      expect(lt::Quad().isNull()).to.beTruthy();
    });

    it(@"should return YES for calls to isNull() if at least one corner is CGPointNull", ^{
      expect(lt::Quad(CGPointZero, CGPointMake(1, 0), CGPointMake(1, 1), CGPointNull).isNull())
      .to.beTruthy();
      expect(lt::Quad(CGPointNull, CGPointMake(1, 0), CGPointMake(1, 1), CGPointNull).isNull())
      .to.beTruthy();
    });

    it(@"should return NO for calls to isNull() if no corner is CGPointNull", ^{
      lt::Quad nonNullQuad(CGPointZero, CGPointMake(1, 0), CGPointMake(1, 1), CGPointMake(0, 1));
      expect(nonNullQuad.isNull()).to.beFalsy();
    });
  });

  context(@"degenerate quads", ^{
    it(@"should consider itself degenerate if it is a point quad", ^{
      CGPoint point = CGPointZero;
      lt::Quad::Corners corners{{point, point, point, point}};
      expect(lt::Quad(corners).isDegenerate()).to.beTruthy();

      point = CGPointMake(7, 8.5);
      corners = {{point, point, point, point}};
      expect(lt::Quad(corners).isDegenerate()).to.beTruthy();
    });

    it(@"should consider itself degenerate if it is a quad with exclusively collinear corners", ^{
      lt::Quad::Corners corners{{CGPointZero, CGPointMake(1, 1), CGPointMake(2, 2),
        CGPointMake(3, 3)
      }};
      expect(lt::Quad(corners).isDegenerate()).to.beTruthy();
    });
  });

  context(@"convexity", ^{
    it(@"should return YES for a convexity query of a convex quad", ^{
      lt::Quad convexQuad = lt::Quad(CGRectMake(v0.x, v0.y, v1.x, v3.y));
      expect(convexQuad.isConvex()).to.beTruthy();
      lt::Quad::Corners cornersOfConvexQuad{{v0, v1, v2, v3}};
      convexQuad = lt::Quad(cornersOfConvexQuad);
      expect(convexQuad.isConvex()).to.beTruthy();
    });

    it(@"should return YES for a convexity query of a triangular quad", ^{
      lt::Quad quad(CGPointZero, CGPointZero, CGPointMake(1, 0), CGPointMake(1, 1));
      expect(quad.isConvex()).to.beTruthy();
    });

    it(@"should return NO for a convexity query of a concave quad", ^{
      lt::Quad::Corners cornersOfConcaveQuad{{v0, v1, w0, v3}};
      lt::Quad concaveQuad(cornersOfConcaveQuad);
      expect(concaveQuad.isConvex()).to.beFalsy();
    });
  });

  context(@"triangularity", ^{
    it(@"should return YES for a triangularity query of a triangular quad", ^{
      lt::Quad quad(CGPointZero, CGPointZero, CGPointMake(1, 0), CGPointMake(1, 1));
      expect(quad.isTriangular()).to.beTruthy();
    });

    it(@"should return NO for a triangularity query of a non-triangular quad", ^{
      lt::Quad::Corners cornersOfConvexQuad{{v0, v1, v2, v3}};
      lt::Quad concaveQuad(cornersOfConvexQuad);
      expect(concaveQuad.isTriangular()).to.beFalsy();
    });
  });

  context(@"self-intersection", ^{
    it(@"should return NO for self-intersection query of a convex quad", ^{
      lt::Quad::Corners cornersOfConvexQuad{{v0, v1, v2, v3}};
      lt::Quad convexQuad(cornersOfConvexQuad);
      expect(convexQuad.isSelfIntersecting()).to.beFalsy();
    });

    it(@"should return NO for self-intersection query of a simple concave quad", ^{
      lt::Quad::Corners cornersOfSimpleConcaveQuad{{v0, v1, w0, v3}};
      lt::Quad concaveQuad(cornersOfSimpleConcaveQuad);
      expect(concaveQuad.isSelfIntersecting()).to.beFalsy();
    });

    it(@"should return YES for self-intersection query of a complex quad", ^{
      lt::Quad::Corners cornersOfComplexQuad{{v0, v1, v3, v2}};
      lt::Quad complexQuad(cornersOfComplexQuad);
      expect(complexQuad.isSelfIntersecting()).to.beTruthy();
    });
  });

  it(@"should correctly compute the minimum edge length of a convex quad", ^{
    lt::Quad::Corners corners{{v0, v1, v2, v3}};
    lt::Quad quad = lt::Quad(corners);
    expect(quad.minimumEdgeLength()).to.beCloseToWithin(0.8999999761581421, kEpsilon);
  });

  it(@"should correctly compute the minimum edge length of a concave quad", ^{
    lt::Quad::Corners corners = lt::Quad::Corners{{v0, v1, w0, v3}};
    lt::Quad quad = lt::Quad(corners);
    expect(quad.minimumEdgeLength()).to.beCloseToWithin(0.7905694246292114, kEpsilon);
  });

  it(@"should correctly compute the minimum edge length of a convex quad", ^{
    lt::Quad::Corners corners{{v0, v1, v2, v3}};
    lt::Quad quad = lt::Quad(corners);
    expect(quad.maximumEdgeLength()).to.beCloseToWithin(1.0049875, kEpsilon);
  });

  it(@"should correctly compute the minimum edge length of a concave quad", ^{
    lt::Quad::Corners corners = lt::Quad::Corners{{v0, v1, w0, v3}};
    lt::Quad quad = lt::Quad(corners);
    expect(quad.maximumEdgeLength()).to.beCloseToWithin(1, kEpsilon);
  });

  context(@"transform", ^{
    __block CGRect canonicalSquare;

    beforeEach(^{
      canonicalSquare = CGRectMake(0, 0, 1, 1);
    });

    it(@"should provide the identity transform for the canonical square", ^{
      lt::Quad quad = lt::Quad(canonicalSquare);
      cv::Mat1f identity = cv::Mat1f::eye(3, 3);
      expect($(LTMatFromGLKMatrix3(quad.transform()))).to.beCloseToMatWithin($(identity), kEpsilon);
    });

    it(@"should provide the correct transformation for non-axis-aligned quads", ^{
      // In iOS, negative values mean clockwise rotation, while positive values in OSX.
#if TARGET_OS_SIMULATOR || TARGET_OS_IPHONE
      const CGFloat kClockwiseAngle = -45.0 / 180.0 * M_PI;
#else
      const CGFloat kClockwiseAngle = 45.0 / 180.0 * M_PI;
#endif

      lt::Quad::Corners corners0{{CGPointMake(0, 0), CGPointMake(M_SQRT1_2, M_SQRT1_2),
        CGPointMake(0, M_SQRT2), CGPointMake(-M_SQRT1_2, M_SQRT1_2)}};
      lt::Quad quad = lt::Quad(corners0);
      GLKMatrix3 expectedTransform = GLKMatrix3MakeRotation(kClockwiseAngle, 0, 0, 1);
      expect($(LTMatFromGLKMatrix3(quad.transform())))
          .to.beCloseToMatWithin($(LTMatFromGLKMatrix3(expectedTransform)), kEpsilon);
      expect($(LTMatFromGLKMatrix3(quad.transform())))
          .to.beCloseToMatWithin($(LTMatFromGLKMatrix3(LTTransformationForQuad(quad))), kEpsilon);

      lt::Quad::Corners corners1{{CGPointMake(5.1, -2.7), CGPointMake(19.2, 22.2),
        CGPointMake(44.34, 190.2), CGPointMake(-29.132, 99.1)}};
      quad = lt::Quad(corners1);
      expect($(LTMatFromGLKMatrix3(quad.transform())))
          .to.beCloseToMatWithin($(LTMatFromGLKMatrix3(LTTransformationForQuad(quad))), kEpsilon);
    });

    it(@"should provide the correct transformation for random quads", ^{
      LTRandom *random = [[LTRandom alloc] initWithSeed:0];

      for (NSUInteger i = 0; i < 1000; ++i) {
        lt::Quad quad = lt::Quad(CGPointMake([random randomDoubleBetweenMin:0 max:1],
                                             [random randomDoubleBetweenMin:0 max:1]),
                                 CGPointMake([random randomDoubleBetweenMin:0 max:1],
                                             [random randomDoubleBetweenMin:0 max:1]),
                                 CGPointMake([random randomDoubleBetweenMin:0 max:1],
                                             [random randomDoubleBetweenMin:0 max:1]),
                                 CGPointMake([random randomDoubleBetweenMin:0 max:1],
                                             [random randomDoubleBetweenMin:0 max:1]));
        GLKMatrix3 matrix = quad.transform();
        GLKMatrix3 referenceMatrix = LTTransformationForQuad(quad);

        for (NSUInteger i = 0; i < 9; ++i) {
          expect(matrix.m[i]).to.beCloseToWithin(referenceMatrix.m[i],
                                                 abs(referenceMatrix.m[i] * 1e-2));
        }

        for (NSUInteger i = 0; i < 3; ++i) {
          expect(GLKVector3Normalize(GLKMatrix3GetRow(matrix, (int)i)))
              .to.beCloseToGLKVectorWithin(GLKVector3Normalize(GLKMatrix3GetRow(referenceMatrix,
                                                                                (int)i)), 5e-4);
        }
      }
    });

    it(@"should return itself when transforming canonical square quad with own transform", ^{
      CGRect canonicalSquare = CGRectFromSize(CGSizeMakeUniform(1));
      lt::Quad quad(canonicalSquare);
      lt::Quad transformedQuad = quad.quadFromTransformedRect(canonicalSquare);
      expect(transformedQuad.isSimilarToQuadUpToDeviation(quad, kEpsilon)).to.beTruthy();
    });

    it(@"should return itself when transforming quad with transform of canonical square", ^{
      lt::Quad quad = lt::Quad(CGRectMake(-0.5, 0, 2, 1));
      lt::Quad transformedQuad = quad.quadFromTransformedRect(canonicalSquare);
      expect(transformedQuad.isSimilarToQuadUpToDeviation(quad, kEpsilon)).to.beTruthy();
    });

    it(@"should create scaled version of quad when transforming with transform of scaled square", ^{
      lt::Quad quad = lt::Quad(CGRectFromSize(CGSizeMakeUniform(2)));
      lt::Quad transformedQuad = quad.quadFromTransformedRect(CGRectFromSize(CGSizeMakeUniform(2)));
      lt::Quad expectedQuad(CGRectFromSize(CGSizeMakeUniform(4)));
      expect(transformedQuad.isSimilarToQuadUpToDeviation(expectedQuad, kEpsilon)).to.beTruthy();
    });

    it(@"should create rotated quad when transforming rotated quad", ^{
      lt::Quad quad(
        CGPointMake(-1, 0),
        CGPointMake(0, -1),
        CGPointMake(1, 0),
        CGPointMake(0, 1)
      );
      lt::Quad expectedQuad(
        CGPointMake(-1, 0),
        CGPointMake(1, -2),
        CGPointMake(2, -1),
        CGPointMake(0, 1)
      );

      lt::Quad transformedQuad = quad.quadFromTransformedRect(CGRectMake(0, 0, 2, 1));

      expect(transformedQuad.isSimilarToQuadUpToDeviation(expectedQuad, kEpsilon)).to.beTruthy();
    });

    it(@"should create non-rect quad when transforming non-rect quad", ^{
      lt::Quad quad(
        CGPointZero,
        CGPointMake(1, 0),
        CGPointMake(0.75, 1),
        CGPointMake(0.25, 1)
      );
      lt::Quad expectedQuad(
        CGPointZero,
        CGPointMake(1, 0),
        CGPointMake(0.833333, 0.666667),
        CGPointMake(0.166667, 0.666667)
      );

      lt::Quad transformedQuad = quad.quadFromTransformedRect(CGRectMake(0, 0, 1, 0.5));

      expect(transformedQuad.isSimilarToQuadUpToDeviation(expectedQuad, kEpsilon)).to.beTruthy();
    });
  });
});

context(@"equality", ^{
  it(@"should consider two quads equal if their non-permutated corners() are equal", ^{
    lt::Quad::Corners corners{{v0, v1, v2, v3}};
    expect(lt::Quad(corners) == lt::Quad(corners)).to.beTruthy();

    lt::Quad::Corners permutatedCorners{{v1, v2, v3, v0}};
    expect(lt::Quad(corners) == lt::Quad(permutatedCorners)).to.beFalsy();
  });

  it(@"should consider two quads inequal if their corners() are inequal", ^{
    lt::Quad::Corners corners{{v0, v1, v2, v3}};
    expect(lt::Quad(corners) != lt::Quad(corners)).to.beFalsy();

    lt::Quad::Corners permutatedCorners{{v1, v2, v3, v0}};
    expect(lt::Quad(corners) != lt::Quad(permutatedCorners)).to.beTruthy();
  });
});

context(@"de/serialization", ^{
  it(@"should return a string from a given quad", ^{
    expect(NSStringFromLTQuad(lt::Quad::canonicalSquare()))
        .to.equal(@"{{0, 0}, {1, 0}, {1, 1}, {0, 1}}");
  });

  context(@"deserialization", ^{
    it(@"should return a quad from a given string", ^{
      expect(LTQuadFromString(@"{{0, 0}, {1, 0}, {1, 1}, {0, 1}}") == lt::Quad::canonicalSquare())
          .to.beTruthy();
    });

    it(@"should return a null quad from a given incorrectly formatted string", ^{
      expect(LTQuadFromString(@"{{0, 0}, {1, 0}, {1, 1}}").isNull()).to.beTruthy();
      expect(LTQuadFromString(@"{}").isNull()).to.beTruthy();
    });
  });
});

SpecEnd
