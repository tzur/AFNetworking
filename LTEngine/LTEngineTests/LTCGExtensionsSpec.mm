// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCGExtensions.h"

SpecBegin(LTCGExtensions)

static const CGFloat kEpsilon = 1e-5;

context(@"null values", ^{
  it(@"should identify null point", ^{
    expect(CGPointIsNull(CGPointNull)).to.beTruthy();
    expect(CGPointIsNull(CGPointZero)).to.beFalsy();
    expect(CGPointIsNull(CGPointMake(INFINITY, INFINITY))).to.beFalsy();
  });
  
  it(@"null point should not be equal to any point (including other null point)", ^{
    expect(CGPointEqualToPoint(CGPointNull, CGPointNull)).to.beFalsy();
    expect(CGPointEqualToPoint(CGPointNull, CGPointZero)).to.beFalsy();
    expect(CGPointEqualToPoint(CGPointNull, CGPointMake(1, 1))).to.beFalsy();
  });
  
  it(@"should identify null size", ^{
    expect(CGSizeIsNull(CGSizeNull)).to.beTruthy();
    expect(CGSizeIsNull(CGSizeZero)).to.beFalsy();
    expect(CGSizeIsNull(CGSizeMake(INFINITY, INFINITY))).to.beFalsy();
  });
  
  it(@"null size should not be equal to any size (including other null size)", ^{
    expect(CGSizeEqualToSize(CGSizeNull, CGSizeNull)).to.beFalsy();
    expect(CGSizeEqualToSize(CGSizeNull, CGSizeZero)).to.beFalsy();
    expect(CGSizeEqualToSize(CGSizeNull, CGSizeMake(1, 1))).to.beFalsy();
  });
});

context(@"uiedgeinsets operations", ^{
  it(@"comparison", ^{
    expect(UIEdgeInsetsMake(1, 2, 3, 4) == UIEdgeInsetsMake(1, 2, 3, 4)).to.beTruthy();
    expect(UIEdgeInsetsMake(1, 2, 3, 4) != UIEdgeInsetsMake(1, 2, 3, 4)).to.beFalsy();
    expect(UIEdgeInsetsMake(1, 2, 3, 4) == UIEdgeInsetsMake(2, 1, 3, 4)).to.beFalsy();
    expect(UIEdgeInsetsMake(1, 2, 3, 4) != UIEdgeInsetsMake(1, 2, 4, 3)).to.beTruthy();
  });
  
  it(@"arithemtic", ^{
    expect(UIEdgeInsetsMake(1, 2, 3, 4) * 2).to.equal(UIEdgeInsetsMake(2, 4, 6, 8));
    expect(0.5 * UIEdgeInsetsMake(1, 2, 3, 4)).to.equal(UIEdgeInsetsMake(0.5, 1, 1.5, 2));
    expect(UIEdgeInsetsMake(1, 2, 3, 4) / 0.5).to.equal(UIEdgeInsetsMake(2, 4, 6, 8));
  });
});

context(@"cgfloat operations", ^{
  it(@"clamping", ^{
    expect(std::clamp(-1, 0, 1)).to.equal(0);
    expect(std::clamp(-1, 1, 0)).to.equal(0);
    expect(std::clamp(2, 0, 1)).to.equal(1);
    expect(std::clamp(2, 1, 0)).to.equal(1);
    expect(std::clamp(0.5, 0, 1)).to.equal(0.5);
    expect(std::clamp(0.5, 1, 0)).to.equal(0.5);
    expect(std::clamp(0.5, 0, 0)).to.equal(0);
    expect(std::clamp(0.5, 1, 1)).to.equal(1);
  });
});

context(@"cgpoint operations", ^{
  it(@"construction", ^{
    expect(CGPointFromSize(CGSizeZero)).to.equal(CGPointZero);
    expect(CGPointIsNull(CGPointFromSize(CGSizeNull))).to.beTruthy();
    expect(CGPointFromSize(CGSizeMake(1, 2))).to.equal(CGPointMake(1, 2));
  });
  
  it(@"comparison", ^{
    expect(CGPointMake(1, 2) == CGPointMake(1, 2)).to.beTruthy();
    expect(CGPointMake(1, 2) != CGPointMake(1, 2)).to.beFalsy();
    expect(CGPointMake(1, 2) == CGPointMake(2, 1)).to.beFalsy();
    expect(CGPointMake(1, 2) != CGPointMake(2, 1)).to.beTruthy();
    expect(CGPointMake(INFINITY, INFINITY) == CGPointMake(INFINITY, INFINITY)).to.beTruthy();
    expect(CGPointMake(INFINITY, INFINITY) != CGPointMake(INFINITY, INFINITY)).to.beFalsy();
    expect(CGPointMake(NAN, NAN) == CGPointMake(NAN, NAN)).to.beFalsy();
    expect(CGPointMake(NAN, NAN) != CGPointMake(NAN, NAN)).to.beTruthy();
  });
  
  it(@"arithmetic", ^{
    expect(CGPointMake(1, 2) + CGPointMake(3, 4)).to.equal(CGPointMake(4, 6));
    expect(CGPointMake(1, 2) + CGSizeMake(3, 4)).to.equal(CGPointMake(4, 6));
    expect(CGSizeMake(3, 4) + CGPointMake(1, 2)).to.equal(CGPointMake(4, 6));
    expect(CGPointMake(3, 4) - CGSizeMake(1, 2)).to.equal(CGPointMake(2, 2));
    expect(CGPointMake(3, 4) - CGPointMake(1, 2)).to.equal(CGPointMake(2, 2));
    expect(CGPointMake(1, 2) * 2).to.equal(CGPointMake(2, 4));
    expect(CGPointMake(1, 2) * CGPointMake(1, 2)).to.equal(CGPointMake(1, 4));
    expect(0.5 * CGPointMake(1, 2)).to.equal(CGPointMake(0.5, 1));
    expect(CGPointMake(1, 2) / 0.5).to.equal(CGPointMake(2, 4));
    expect(CGPointMake(1, 2) * CGSizeMake(3, 4)).to.equal(CGPointMake(3, 8));
    expect(CGPointMake(1, 2) / CGSizeMake(0.5, 0.25)).to.equal(CGPointMake(2, 8));

    // In iOS, negative values mean clockwise rotation, while positive values in OSX.
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    const CGFloat kClockwiseAngle = -M_PI_2;
#else
    const CGFloat kClockwiseAngle = M_PI_2;
#endif
    CGPoint point = CGAffineTransformMakeRotation(kClockwiseAngle) * CGPointMake(1, 2);
    expect(point.x).to.beCloseTo(2);
    expect(point.y).to.beCloseTo(-1);
  });
  
  it(@"clamping", ^{
    expect(std::clamp(CGPointMake(0.5, -0.5), 0, 1)).to.equal(CGPointMake(0.5, 0));
    expect(std::clamp(CGPointMake(0.5, -0.5), 1, 0)).to.equal(CGPointMake(0.5, 0));
    expect(std::clamp(CGPointMake(0.5, -0.5), -1, 0)).to.equal(CGPointMake(0, -0.5));
    expect(std::clamp(CGPointMake(0.5, -0.5), 0, -1)).to.equal(CGPointMake(0, -0.5));

    expect(std::clamp(CGPointMake(0.5, -0.5), CGPointMake(0, 0),
                      CGPointMake(1, 1))).to.equal(CGPointMake(0.5, 0));
    expect(std::clamp(CGPointMake(0.5, -0.5), CGPointMake(-1, 0),
                      CGPointMake(1, 1))).to.equal(CGPointMake(0.5, 0));
    expect(std::clamp(CGPointMake(0.5, -0.5), CGPointMake(-1, -1),
                      CGPointMake(0, 1))).to.equal(CGPointMake(0, -0.5));

    expect(std::clamp(CGPointMake(0.5, -0.5),
                      CGRectMake(0, 0, 1, 1))).to.equal(CGPointMake(0.5, 0));
    expect(std::clamp(CGPointMake(0.5, -0.5),
                      CGRectMake(0, 0, 1, 1))).to.equal(CGPointMake(0.5, 0));
    expect(std::clamp(CGPointMake(0.5, -0.5),
                      CGRectMake(0, 0, -1, -1))).to.equal(CGPointMake(0, -0.5));
    expect(std::clamp(CGPointMake(0.5, -0.5),
                      CGRectMake(0, 0, -1, -1))).to.equal(CGPointMake(0, -0.5));
  });
});

context(@"cgsize operations", ^{
  it(@"construction", ^{
    expect(CGSizeMakeUniform(0)).to.equal(CGSizeZero);
    expect(CGSizeMakeUniform(1)).to.equal(CGSizeMake(1, 1));
    expect(CGSizeMakeUniform(-1)).to.equal(CGSizeMake(-1, -1));
  });
  
  it(@"comparison", ^{
    expect(CGSizeMake(1, 2) == CGSizeMake(1, 2)).to.beTruthy();
    expect(CGSizeMake(1, 2) != CGSizeMake(1, 2)).to.beFalsy();
    expect(CGSizeMake(1, 2) == CGSizeMake(2, 1)).to.beFalsy();
    expect(CGSizeMake(1, 2) != CGSizeMake(2, 1)).to.beTruthy();
    expect(CGSizeMake(INFINITY, INFINITY) == CGSizeMake(INFINITY, INFINITY)).to.beTruthy();
    expect(CGSizeMake(INFINITY, INFINITY) != CGSizeMake(INFINITY, INFINITY)).to.beFalsy();
    expect(CGSizeMake(NAN, NAN) == CGSizeMake(NAN, NAN)).to.beFalsy();
    expect(CGSizeMake(NAN, NAN) != CGSizeMake(NAN, NAN)).to.beTruthy();
  });
  
  it(@"arithmetic", ^{
    expect(CGSizeMake(1, 2) + CGSizeMake(3, 4)).to.equal(CGSizeMake(4, 6));
    expect(CGSizeMake(1, 2) + 1).to.equal(CGSizeMake(2, 3));
    expect(1 + CGSizeMake(1, 2)).to.equal(CGSizeMake(2, 3));
    expect(CGSizeMake(3, 4) - CGSizeMake(1, 2)).to.equal(CGSizeMake(2, 2));
    expect(CGSizeMake(1, 2) * 2).to.equal(CGSizeMake(2, 4));
    expect(0.5 * CGSizeMake(1, 2)).to.equal(CGSizeMake(0.5, 1));
    expect(CGSizeMake(1, 2) / 0.5).to.equal(CGSizeMake(2, 4));
    expect(CGSizeMake(3, 4) / CGSizeMake(2, 3)).to.equal(CGSizeMake(3 / 2.0, 4 / 3.0));
    expect(CGSizeMake(3, 4) * CGSizeMake(2, 3)).to.equal(CGSizeMake(3 * 2, 4 * 3));
  });
  
  it(@"min/max", ^{
    expect(std::min(CGSizeMake(1, 2))).to.equal(1);
    expect(std::min(CGSizeMake(2, 1))).to.equal(1);
    expect(std::max(CGSizeMake(1, 2))).to.equal(2);
    expect(std::max(CGSizeMake(2, 1))).to.equal(2);
  });
});

context(@"cgrect operations", ^{
  it(@"comparison", ^{
    expect(CGRectMake(1, 2, 3, 4) == CGRectMake(1, 2, 3, 4)).to.beTruthy();
    expect(CGRectMake(1, 2, 3, 4) != CGRectMake(1, 2, 3, 4)).to.beFalsy();
    expect(CGRectMake(1, 2, 3, 4) == CGRectMake(1, 2, 4, 3)).to.beFalsy();
    expect(CGRectMake(1, 2, 3, 4) != CGRectMake(1, 2, 4, 3)).to.beTruthy();
    expect(CGRectMake(1, 2, 3, 4) == CGRectMake(2, 1, 3, 4)).to.beFalsy();
    expect(CGRectMake(1, 2, 3, 4) != CGRectMake(2, 1, 3, 4)).to.beTruthy();
    expect(CGRectNull == CGRectNull).to.beTruthy();
    expect(CGRectNull != CGRectNull).to.beFalsy();
  });

  it(@"construction", ^{
    expect(CGRectFromSize(CGSizeMake(1, 2))).to.equal(CGRectMake(0, 0, 1, 2));
    expect(CGRectFromEdges(1, 2, 3, 4)).to.equal(CGRectMake(1, 2, 2, 2));
    expect(CGRectFromEdges(3, 4, 1, 2)).to.equal(CGRectMake(3, 4, -2, -2));
    expect(CGRectFromPoints(CGPointMake(1, 2), CGPointMake(3, 4))).to.equal(CGRectMake(1, 2, 2, 2));
    expect(CGRectFromPoints(CGPointMake(3, 4),
                            CGPointMake(1, 2))).to.equal(CGRectMake(3, 4, -2, -2));
    expect(CGRectFromOriginAndSize(CGPointMake(1, 2),
                                   CGSizeMake(3, 4))).to.equal(CGRectMake(1, 2, 3, 4));
    expect(CGRectFromOriginAndSize(CGPointMake(1, 2),
                                   CGSizeMake(-3, -4))).to.equal(CGRectMake(1, 2, -3, -4));
    expect(CGRectCenteredAt(CGPointMake(3, 4),
                            CGSizeMake(1, 2))).to.equal(CGRectMake(2.5, 3, 1, 2));
    expect(CGRectCenteredAt(CGPointMake(3, 4),
                            CGSizeMake(-1, -2))).to.equal(CGRectMake(3.5, 5, -1, -2));
  });
  
  it(@"arithmetic", ^{
    expect(CGRectCenter(CGRectMake(1, 2, 3, 4))).to.equal(CGPointMake(2.5, 4));
  });
});

context(@"cgtriangle operations", ^{
  it(@"triangle make", ^{
    CGPoint a = CGPointMake(1, 2);
    CGPoint b = CGPointMake(3, 4);
    CGPoint c = CGPointMake(-5, 6);
    CGTriangle triangle = CGTriangleMake(a, b, c);
    expect(triangle.a).to.equal(a);
    expect(triangle.b).to.equal(b);
    expect(triangle.c).to.equal(c);
  });
  
  it(@"triangle edge mask make", ^{
    expect(CGTriangleEdgeMaskMake(NO, NO, NO)).to.equal(CGTriangleEdgeNone);
    expect(CGTriangleEdgeMaskMake(YES, NO, NO)).to.equal(CGTriangleEdgeAB);
    expect(CGTriangleEdgeMaskMake(NO, YES, NO)).to.equal(CGTriangleEdgeBC);
    expect(CGTriangleEdgeMaskMake(NO, NO, YES)).to.equal(CGTriangleEdgeCA);
    expect(CGTriangleEdgeMaskMake(YES, YES, NO)).to.equal(CGTriangleEdgeAB | CGTriangleEdgeBC);
    expect(CGTriangleEdgeMaskMake(YES, NO, YES)).to.equal(CGTriangleEdgeAB | CGTriangleEdgeCA);
    expect(CGTriangleEdgeMaskMake(NO, YES, YES)).to.equal(CGTriangleEdgeBC | CGTriangleEdgeCA);
    expect(CGTriangleEdgeMaskMake(YES, YES, YES)).to.equal(CGTriangleEdgeAll);
  });
});

it(@"distance functions", ^{
  expect(CGPointDistance(CGPointZero, CGPointMake(1, 2))).to.beCloseTo(sqrt(5));
  expect(CGPointDistance(CGPointZero, CGPointMake(1, 2))).to.beCloseTo(sqrt(5));
  expect(CGPointDistance(CGPointMake(1, 2), CGPointZero)).to.beCloseTo(sqrt(5));
  expect(CGPointDistance(CGPointMake(1, 2), CGPointMake(-2, -2))).to.beCloseTo(5);
  expect(CGPointDistanceSquared(CGPointZero, CGPointMake(1, 2))).to.beCloseTo(5);
  expect(CGPointDistanceSquared(CGPointMake(1, 2), CGPointZero)).to.beCloseTo(5);
  expect(CGPointDistanceSquared(CGPointMake(1, 2), CGPointMake(-2, -2))).to.beCloseTo(25);
});

context(@"rounding cgstructs", ^{
  it(@"rounding cgpoints", ^{
    const CGPoint point = CGPointMake(0.4, 0.6);
    expect(std::floor(point)).to.equal(CGPointMake(0, 0));
    expect(std::ceil(point)).to.equal(CGPointMake(1, 1));
    expect(std::round(point)).to.equal(CGPointMake(0, 1));
    expect(std::floor(-1 * point)).to.equal(CGPointMake(-1, -1));
    expect(std::ceil(-1 * point)).to.equal(CGPointMake(0, 0));
    expect(std::round(-1 * point)).to.equal(CGPointMake(0, -1));
  });
  
  it(@"rounding cgsizes", ^{
    const CGSize size = CGSizeMake(0.4, 0.6);
    expect(std::floor(size)).to.equal(CGSizeMake(0, 0));
    expect(std::ceil(size)).to.equal(CGSizeMake(1, 1));
    expect(std::round(size)).to.equal(CGSizeMake(0, 1));
    expect(std::floor(-1 * size)).to.equal(CGSizeMake(-1, -1));
    expect(std::ceil(-1 * size)).to.equal(CGSizeMake(0, 0));
    expect(std::round(-1 * size)).to.equal(CGSizeMake(0, -1));
  });
  
  it(@"rounding cgrects", ^{
    const CGRect rect = CGRectFromEdges(0.4, 0.6, 2.6, 2.4);
    expect(CGRoundRect(rect)).to.equal(CGRectFromEdges(0, 1, 3, 2));
    expect(CGRoundRectInside(rect)).to.equal(CGRectFromEdges(1, 1, 2, 2));
    expect(CGRoundRectOutside(rect)).to.equal(CGRectFromEdges(0, 0, 3, 3));
  });
});

context(@"scaling down cgsizes", ^{
  it(@"should scale down correctly", ^{
    CGSize inputSize = CGSizeMake(20, 10);
    CGSize outputSize = CGScaleDownToDimension(inputSize, 10);
    expect(outputSize).to.equal(CGSizeMake(10, 5));
  });
  
  it(@"should scale down correctly with rounding", ^{
    CGSize inputSize = CGSizeMake(201, 100);
    CGSize outputSize = CGScaleDownToDimension(inputSize, 10);
    expect(outputSize).to.equal(CGSizeMake(10, 5));
  });
  
  it(@"should scale down, without setting any side below 1", ^{
    CGSize inputSize = CGSizeMake(100, 2);
    CGSize outputSize = CGScaleDownToDimension(inputSize, 10);
    expect(outputSize).to.equal(CGSizeMake(10, 1));
  });
  
  it(@"should not scale up and return the original size", ^{
    CGSize inputSize = CGSizeMake(10, 10);
    CGSize outputSize = CGScaleDownToDimension(inputSize, 100);
    expect(outputSize).to.equal(inputSize);
  });
});

context(@"fitting cgsizes", ^{
  context(@"rounding to integer values", ^{
    it(@"should round output values", ^{
      CGSize inputSize = CGSizeMake(19.5, 9.5);
      CGSize fitSize = CGSizeMake(10, 7);
      CGSize outputSize = CGSizeAspectFit(inputSize, fitSize);
      expect(outputSize).to.equal(CGSizeMake(10, 5));
      
      CGSize fillSize = CGSizeMake(10, 2);
      outputSize = CGSizeAspectFill(inputSize, fillSize);
      expect(outputSize).to.equal(CGSizeMake(10, 5));
    });
    
    it(@"should aspect fit by scaling down size by width", ^{
      CGSize inputSize = CGSizeMake(20, 10);
      CGSize fitSize = CGSizeMake(10, 7);
      CGSize outputSize = CGSizeAspectFit(inputSize, fitSize);
      expect(outputSize).to.equal(CGSizeMake(10, 5));
    });
    
    it(@"should aspect fit by scaling down size by height", ^{
      CGSize inputSize = CGSizeMake(9, 21);
      CGSize fitSize = CGSizeMake(10, 7);
      CGSize outputSize = CGSizeAspectFit(inputSize, fitSize);
      expect(outputSize).to.equal(CGSizeMake(3, 7));
    });
    
    it(@"should aspect fit by scaling up size", ^{
      CGSize inputSize = CGSizeMake(20, 10);
      CGSize fitSize = CGSizeMake(40, 40);
      CGSize outputSize = CGSizeAspectFit(inputSize, fitSize);
      expect(outputSize).to.equal(CGSizeMake(40, 20));
    });
    
    it(@"should aspect fill by scaling down size by width", ^{
      CGSize inputSize = CGSizeMake(20, 10);
      CGSize fitSize = CGSizeMake(10, 2);
      CGSize outputSize = CGSizeAspectFill(inputSize, fitSize);
      expect(outputSize).to.equal(CGSizeMake(10, 5));
    });
    
    it(@"should aspect fill by scaling down size by height", ^{
      CGSize inputSize = CGSizeMake(45, 21);
      CGSize fitSize = CGSizeMake(10, 7);
      CGSize outputSize = CGSizeAspectFill(inputSize, fitSize);
      expect(outputSize).to.equal(CGSizeMake(15, 7));
    });

    it(@"should aspect fill by scaling up size", ^{
      CGSize inputSize = CGSizeMake(20, 10);
      CGSize fitSize = CGSizeMake(40, 40);
      CGSize outputSize = CGSizeAspectFill(inputSize, fitSize);
      expect(outputSize).to.equal(CGSizeMake(80, 40));
    });
  });

  context(@"no rounding to integer values", ^{
    it(@"should not round output values", ^{
      CGSize inputSize = CGSizeMake(19.5, 9.5);
      CGSize fitSize = CGSizeMake(10, 7);
      CGSize outputSize = CGSizeAspectFitWithoutRounding(inputSize, fitSize);
      expect(CGPointFromSize(outputSize)).to.beCloseToPointWithin(CGPointMake(10, 4.871795),
                                                                  kEpsilon);
      
      CGSize fillSize = CGSizeMake(10, 2);
      outputSize = CGSizeAspectFillWithoutRounding(inputSize, fillSize);
      expect(CGPointFromSize(outputSize)).to.beCloseToPointWithin(CGPointMake(10, 4.871795),
                                                                  kEpsilon);
    });
    
    it(@"should aspect fit by scaling down size by width", ^{
      CGSize inputSize = CGSizeMake(19.5, 9.5);
      CGSize fitSize = CGSizeMake(10, 7);
      CGSize outputSize = CGSizeAspectFitWithoutRounding(inputSize, fitSize);
      expect(CGPointFromSize(outputSize)).to.beCloseToPointWithin(CGPointMake(10, 4.871795),
                                                                  kEpsilon);
    });
    
    it(@"should aspect fit by scaling down size by height", ^{
      CGSize inputSize = CGSizeMake(8.5, 20.5);
      CGSize fitSize = CGSizeMake(10, 7);
      CGSize outputSize = CGSizeAspectFitWithoutRounding(inputSize, fitSize);
      expect(CGPointFromSize(outputSize)).to.beCloseToPointWithin(CGPointMake(2.902439, 7),
                                                                  kEpsilon);
    });
    
    it(@"should aspect fit by scaling up size", ^{
      CGSize inputSize = CGSizeMake(19.5, 9.5);
      CGSize fitSize = CGSizeMake(40, 40);
      CGSize outputSize = CGSizeAspectFitWithoutRounding(inputSize, fitSize);
      expect(CGPointFromSize(outputSize)).to.beCloseToPointWithin(CGPointMake(40, 19.487181),
                                                                  kEpsilon);
    });
    
    it(@"should aspect fill by scaling down size by width", ^{
      CGSize inputSize = CGSizeMake(19.5, 9.5);
      CGSize fitSize = CGSizeMake(10, 2);
      CGSize outputSize = CGSizeAspectFillWithoutRounding(inputSize, fitSize);
      expect(CGPointFromSize(outputSize)).to.beCloseToPointWithin(CGPointMake(10, 4.871795),
                                                                  kEpsilon);
    });
    
    it(@"should aspect fill by scaling down size by height", ^{
      CGSize inputSize = CGSizeMake(44.5, 20.5);
      CGSize fitSize = CGSizeMake(10, 7);
      CGSize outputSize = CGSizeAspectFillWithoutRounding(inputSize, fitSize);
      expect(CGPointFromSize(outputSize)).to.beCloseToPointWithin(CGPointMake(15.195122, 7),
                                                                  kEpsilon);
    });
    
    it(@"should aspect fill by scaling up size", ^{
      CGSize inputSize = CGSizeMake(19.5, 9.5);
      CGSize fitSize = CGSizeMake(40, 40);
      CGSize outputSize = CGSizeAspectFillWithoutRounding(inputSize, fitSize);
      expect(CGPointFromSize(outputSize)).to.beCloseToPointWithin(CGPointMake(82.105263, 40),
                                                                  kEpsilon);
    });
  });
});

static const CGFloat kAllowedAngleDeviation = 5e-7;

it(@"should convert a given angle to the canonical range [0, 2 * M_PI)", ^{
  expect(CGNormalizedAngle(-2 * M_PI)).to.equal(0);
  expect(CGNormalizedAngle(-3 * M_PI_2)).to.beCloseToWithin(M_PI_2, kAllowedAngleDeviation);
  expect(CGNormalizedAngle(-M_PI)).to.beCloseToWithin(M_PI, kAllowedAngleDeviation);
  expect(CGNormalizedAngle(-M_PI_2)).to.beCloseToWithin(3 * M_PI_2, kAllowedAngleDeviation);
  expect(CGNormalizedAngle(-M_PI_4)).to.beCloseToWithin(2 * M_PI - M_PI_4,
                                                        kAllowedAngleDeviation);

  expect(CGNormalizedAngle(0)).to.equal(0);
  expect(CGNormalizedAngle(M_PI_4)).to.equal(M_PI_4);
  expect(CGNormalizedAngle(M_PI_2)).to.equal(M_PI_2);
  expect(CGNormalizedAngle(M_PI)).to.equal(M_PI);
  expect(CGNormalizedAngle(3 * M_PI_2)).to.equal(3 * M_PI_2);

  expect(CGNormalizedAngle(2 * M_PI)).to.beCloseToWithin(0, kAllowedAngleDeviation);
  expect(CGNormalizedAngle(2 * M_PI + M_PI_4)).to.beCloseToWithin(M_PI_4, kAllowedAngleDeviation);
  expect(CGNormalizedAngle(2 * M_PI + M_PI_2)).to.beCloseToWithin(M_PI_2, kAllowedAngleDeviation);
  expect(CGNormalizedAngle(3 * M_PI)).to.beCloseToWithin(M_PI, kAllowedAngleDeviation);
  expect(CGNormalizedAngle(2 * M_PI + 3 * M_PI_2)).to.beCloseToWithin(3 * M_PI_2,
                                                                      kAllowedAngleDeviation);
  expect(CGNormalizedAngle(-0.000000042136203859399756765924394130706787109375))
      .to.beLessThan(2 * M_PI);
});

SpecEnd
