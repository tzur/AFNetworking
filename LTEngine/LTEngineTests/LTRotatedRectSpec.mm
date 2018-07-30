// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRotatedRect.h"

SpecBegin(LTRotatedRect)

const CGRect kRect = CGRectMake(1, 2, 3, 4);
const CGFloat kAngle = M_PI_4;
const CGPoint kCenter = CGRectCenter(kRect);

__block LTRotatedRect *rotatedRect;

context(@"initializers and factory methods", ^{
  context(@"initializers", ^{
    it(@"should initialize with rect", ^{
      rotatedRect = [[LTRotatedRect alloc] initWithRect:kRect angle:kAngle];
      expect(rotatedRect.rect).to.equal(kRect);
      expect(rotatedRect.angle).to.equal(kAngle);
      expect(rotatedRect.center).to.equal(kCenter);
    });

    it(@"should initialize with center", ^{
      rotatedRect = [[LTRotatedRect alloc] initWithCenter:kCenter size:kRect.size angle:kAngle];
      expect(rotatedRect.rect).to.equal(kRect);
      expect(rotatedRect.angle).to.equal(kAngle);
      expect(rotatedRect.center).to.equal(kCenter);
    });
  });

  context(@"class Methods", ^{
    it(@"should create rect with angle", ^{
      rotatedRect = [LTRotatedRect rect:kRect withAngle:kAngle];
      expect(rotatedRect.rect).to.equal(kRect);
      expect(rotatedRect.angle).to.equal(kAngle);
      expect(rotatedRect.center).to.equal(kCenter);
    });

    it(@"should create rect from center", ^{
      rotatedRect = [LTRotatedRect rectWithCenter:kCenter size:kRect.size angle:kAngle];
      expect(rotatedRect.rect).to.equal(kRect);
      expect(rotatedRect.angle).to.equal(kAngle);
      expect(rotatedRect.center).to.equal(kCenter);
    });

    it(@"should create rect from size, translation, scaling and rotation", ^{
      rotatedRect = [LTRotatedRect rectWithSize:CGSizeMake(4, 10)
                                    translation:CGPointMake(4, 2)
                                        scaling:2
                                    andRotation:kAngle];
      expect(rotatedRect.rect).to.equal(CGRectMake(2, -3, 8, 20));
      expect(rotatedRect.angle).to.equal(kAngle);
      expect(rotatedRect.center).to.equal(CGPointMake(6, 7));
    });

    it(@"should create square from center", ^{
      const CGFloat kLength = 3;
      rotatedRect = [LTRotatedRect squareWithCenter:kCenter length:kLength angle:kAngle];
      expect(rotatedRect.rect).to.equal(CGRectCenteredAt(kCenter, CGSizeMake(kLength,kLength)));
      expect(rotatedRect.angle).to.equal(kAngle);
      expect(rotatedRect.center).to.equal(kCenter);
    });
  });
});

context(@"properties", ^{
  const CGFloat kAcceptedDifference = 1e-3;

  beforeEach(^{
    rotatedRect = [LTRotatedRect rect:kRect withAngle:kAngle];
  });

  it(@"should return correct vertices", ^{
    const CGPoint expectedV0 = CGPointMake(2.8536, 1.5251);
    const CGPoint expectedV1 = CGPointMake(4.9749, 3.6464);
    const CGPoint expectedV2 = CGPointMake(2.1464, 6.4749);
    const CGPoint expectedV3 = CGPointMake(0.0251, 4.3536);

    expect(rotatedRect.v0.x).to.beCloseToWithin(expectedV0.x, kAcceptedDifference);
    expect(rotatedRect.v0.y).to.beCloseToWithin(expectedV0.y, kAcceptedDifference);
    expect(rotatedRect.v1.x).to.beCloseToWithin(expectedV1.x, kAcceptedDifference);
    expect(rotatedRect.v1.y).to.beCloseToWithin(expectedV1.y, kAcceptedDifference);
    expect(rotatedRect.v2.x).to.beCloseToWithin(expectedV2.x, kAcceptedDifference);
    expect(rotatedRect.v2.y).to.beCloseToWithin(expectedV2.y, kAcceptedDifference);
    expect(rotatedRect.v3.x).to.beCloseToWithin(expectedV3.x, kAcceptedDifference);
    expect(rotatedRect.v3.y).to.beCloseToWithin(expectedV3.y, kAcceptedDifference);
  });

  it(@"should return correct transform", ^{
    expect(rotatedRect.transform.a).to.beCloseToWithin(std::cos(kAngle), kAcceptedDifference);
    expect(rotatedRect.transform.b).to.beCloseToWithin(std::sin(kAngle), kAcceptedDifference);
    expect(rotatedRect.transform.c).to.beCloseToWithin(-std::sin(kAngle), kAcceptedDifference);
    expect(rotatedRect.transform.d).to.beCloseToWithin(std::cos(kAngle), kAcceptedDifference);
    expect(rotatedRect.transform.tx).to.beCloseToWithin(3.5607, kAcceptedDifference);
    expect(rotatedRect.transform.ty).to.beCloseToWithin(-0.5962, kAcceptedDifference);
  });

  it(@"should return correct bounding rect", ^{
    CGRect boundingRect = rotatedRect.boundingRect;
    expect(boundingRect.origin.x).to.beCloseToWithin(0.0251, kAcceptedDifference);
    expect(boundingRect.origin.y).to.beCloseToWithin(1.5251, kAcceptedDifference);
    expect(boundingRect.size.width).to.beCloseToWithin(4.9749 - 0.0251, kAcceptedDifference);
    expect(boundingRect.size.height).to.beCloseToWithin(6.4749 - 1.5251, kAcceptedDifference);
  });
});

context(@"point containment", ^{
  context(@"axis-aligned rect", ^{
    __block LTRotatedRect *rect;

    beforeEach(^{
      rect = [LTRotatedRect rect:CGRectMake(0, 0, 1, 1)];
    });

    it(@"should return true for points inside the rect", ^{
      expect([rect containsPoint:rect.center]).to.beTruthy();
      expect([rect containsPoint:rect.v0]).to.beTruthy();
      expect([rect containsPoint:rect.v3 - CGPointMake(0, 0.01)]).to.beTruthy();
    });

    it(@"should return false for points outside the rect", ^{
      expect([rect containsPoint:rect.v1]).to.beFalsy();
      expect([rect containsPoint:rect.v2]).to.beFalsy();
    });
  });

  context(@"non axis-aligned rect", ^{
    __block LTRotatedRect *rect;

    beforeEach(^{
      rect = [LTRotatedRect rect:kRect withAngle:kAngle];
    });

    it(@"should return true for points inside the rect", ^{
      expect([rect containsPoint:rect.center]).to.beTruthy();
      expect([rect containsPoint:rect.v0 + CGPointMake(0, 0.01)]).to.beTruthy();
      expect([rect containsPoint:rect.v3 + CGPointMake(0.01, 0)]).to.beTruthy();
    });

    it(@"should return false for points outside the rect", ^{
      expect([rect containsPoint:rect.v1 + CGPointMake(0.01, 0)]).to.beFalsy();
      expect([rect containsPoint:rect.v2 + CGPointMake(0, 0.01)]).to.beFalsy();
    });
  });
});

context(@"equality and hash", ^{
  __block LTRotatedRect *a;
  __block LTRotatedRect *b;
  __block LTRotatedRect *c;

  beforeEach(^{
    a = [LTRotatedRect rect:CGRectMake(0, 1, 2, 3) withAngle:M_PI];
    b = [LTRotatedRect rect:CGRectMake(0, 1, 2, 3) withAngle:M_PI];
    c = [LTRotatedRect rect:CGRectMake(0, 1, 2, 3) withAngle:M_PI_2];
  });

  it(@"should return yes for equal objects", ^{
    expect(a).to.equal(b);
  });

  it(@"should return no for non-equal objects", ^{
    expect(a).toNot.equal(c);
    expect(b).toNot.equal(c);
  });

  it(@"should have same hash value for equal rects", ^{
    expect([a hash]).to.equal([b hash]);
  });
});

context(@"copying", ^{
  it(@"should copy rotated rect", ^{
    LTRotatedRect *a = [LTRotatedRect rect:CGRectMake(0, 1, 2, 3) withAngle:0.5];
    LTRotatedRect *b = [a copy];

    NSString *aAddress = [NSString stringWithFormat:@"%p", a];
    NSString *bAddress = [NSString stringWithFormat:@"%p", b];
    expect(aAddress).toNot.equal(bAddress);
    expect(a).to.equal(b);
  });
});

SpecEnd
