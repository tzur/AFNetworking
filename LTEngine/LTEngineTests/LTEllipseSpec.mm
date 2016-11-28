// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "LTEllipse.h"

SpecBegin(LTEllipse)

const CGFloat kEpsilon = 1e-5;

__block CGFloat majorAxisLength;
__block CGFloat minorAxisLength;
__block CGPoint center;
__block CGFloat angle;
__block lt::Ellipse ellipse;

beforeEach(^{
  majorAxisLength = 10;
  minorAxisLength = 5;
  center = CGPointMake(20, 30);
  angle = M_PI_2;
  ellipse = lt::Ellipse(center, angle, majorAxisLength, minorAxisLength);
});

context(@"initialization", ^{
  it(@"should initialize using designated initializer", ^{
    expect(ellipse.majorAxisLength).to.equal(majorAxisLength);
    expect(ellipse.minorAxisLength).to.equal(minorAxisLength);
    expect(ellipse.center).to.equal(center);
    expect(ellipse.angle).to.equal(angle);
  });
});

context(@"transformations", ^{
  it(@"should scale correctly", ^{
    lt::Ellipse scaledEllipse = ellipse.scaledBy(0.5, 2);

    expect(scaledEllipse.majorAxisLength).to.equal(majorAxisLength * 0.5);
    expect(scaledEllipse.minorAxisLength).to.equal(minorAxisLength * 2);
    expect(scaledEllipse.center).to.equal(center);
    expect(scaledEllipse.angle).to.equal(angle);
  });
  
  it(@"should rotate around center correctly", ^{
    lt::Ellipse rotatedEllipse = ellipse.rotatedBy(M_PI_2);

    expect(rotatedEllipse.majorAxisLength).to.equal(majorAxisLength);
    expect(rotatedEllipse.minorAxisLength).to.equal(minorAxisLength);
    expect(rotatedEllipse.center).to.equal(center);
    expect(rotatedEllipse.angle).to.equal(M_PI);
  });
  
  it(@"should rotate around zero point correctly", ^{
    lt::Ellipse rotatedEllipse = ellipse.rotatedAroundPointBy(CGPointZero, M_PI_2);

    expect(rotatedEllipse.majorAxisLength).to.equal(majorAxisLength);
    expect(rotatedEllipse.minorAxisLength).to.equal(minorAxisLength);
    expect(rotatedEllipse.center.x).to.beCloseToWithin(-30, kEpsilon);
    expect(rotatedEllipse.center.y).to.beCloseToWithin(20, kEpsilon);
    expect(rotatedEllipse.angle).to.equal(M_PI);
  });
  
  it(@"should translate correctly", ^{
    CGPoint translation = CGPointMake(5, 10);
    lt::Ellipse translatedEllipse = ellipse.translatedBy(translation);

    expect(translatedEllipse.majorAxisLength).to.equal(majorAxisLength);
    expect(translatedEllipse.minorAxisLength).to.equal(minorAxisLength);
    expect(translatedEllipse.center).to.equal(center + translation);
    expect(translatedEllipse.angle).to.equal(angle);
  });
});

context(@"point inclusion", ^{
  it(@"should correctly compute point inclusion", ^{
    CGFloat semiMinorAxis = minorAxisLength / 2;
    CGFloat semiMajorAxis = majorAxisLength / 2;

    expect(ellipse.containsPoint(CGPointZero)).to.beFalsy();
    expect(ellipse.containsPoint(center)).to.beTruthy();
    expect(ellipse.containsPoint(CGPointMake(center.x + semiMinorAxis - kEpsilon, center.y)))
        .to.beTruthy();
    expect(ellipse.containsPoint(CGPointMake(center.x, center.y + semiMajorAxis - kEpsilon)))
        .to.beTruthy();
    expect(ellipse.containsPoint(CGPointMake(center.x + semiMinorAxis + kEpsilon, center.y)))
        .to.beFalsy();
    expect(ellipse.containsPoint(CGPointMake(center.x, center.y + semiMajorAxis + kEpsilon)))
        .to.beFalsy();
  });
});

context(@"operators", ^{
  it(@"should return YES when ellipses are equal", ^{
    expect(ellipse == lt::Ellipse(ellipse)).to.beTruthy();
  });
  
  it(@"should return NO when ellipses are not equal", ^{
    expect(ellipse != lt::Ellipse()).to.beTruthy();
  });
});

context(@"hash", ^{
  it(@"should return the same hash value for equal objects", ^{
    expect(std::hash<lt::Ellipse>()(ellipse))
        .to.equal(std::hash<lt::Ellipse>()(lt::Ellipse(ellipse)));
  });
});

SpecEnd
