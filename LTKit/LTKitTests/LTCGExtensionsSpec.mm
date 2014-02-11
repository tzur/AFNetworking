// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCGExtensions.h"

SpecBegin(LTCGExtensions)

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

context(@"cgpoint operations", ^{
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
    expect(CGPointMake(1, 2) + CGSizeMake(3, 4)).to.equal(CGPointMake(4, 6));
    expect(CGPointMake(3, 4) - CGSizeMake(1, 2)).to.equal(CGPointMake(2, 2));
    expect(CGPointMake(3, 4) - CGPointMake(1, 2)).to.equal(CGSizeMake(2, 2));
    expect(CGPointMake(1, 2) * 2).to.equal(CGPointMake(2, 4));
    expect(0.5 * CGPointMake(1, 2)).to.equal(CGPointMake(0.5, 1));
    expect(CGPointMake(1, 2) / 0.5).to.equal(CGPointMake(2, 4));
    expect(CGPointMake(1, 2) * CGSizeMake(3, 4)).to.equal(CGPointMake(3, 8));
    expect(CGPointMake(1, 2) / CGSizeMake(0.5, 0.25)).to.equal(CGPointMake(2, 8));

    // in iOS, negative values mean clockwise rotation, while positive values in OSX.
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    const CGFloat cwAngle = -M_PI_2;
#else
    const CGFloat cwAngle = M_PI_2;
#endif
    expect(CGAffineTransformMakeRotation(cwAngle) * CGPointMake(1, 2)).to.equal(CGPointMake(2, -1));
  });
});

context(@"cgsize operations", ^{
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

SpecEnd
