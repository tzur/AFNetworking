// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRotatedRect.h"

#import "LTCGExtensions.h"

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
    const CGPoint expectedV0 = CGPointMake(0.0251, 3.6464);
    const CGPoint expectedV1 = CGPointMake(2.1464, 1.5251);
    const CGPoint expectedV2 = CGPointMake(4.9749, 4.3536);
    const CGPoint expectedV3 = CGPointMake(2.8536, 6.4749);
    
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
    expect(rotatedRect.transform.b).to.beCloseToWithin(-std::sin(kAngle), kAcceptedDifference);
    expect(rotatedRect.transform.c).to.beCloseToWithin(std::sin(kAngle), kAcceptedDifference);
    expect(rotatedRect.transform.d).to.beCloseToWithin(std::cos(kAngle), kAcceptedDifference);
    expect(rotatedRect.transform.tx).to.beCloseToWithin(-2.0961, kAcceptedDifference);
    expect(rotatedRect.transform.ty).to.beCloseToWithin(2.9393, kAcceptedDifference);
  });
});

SpecEnd
