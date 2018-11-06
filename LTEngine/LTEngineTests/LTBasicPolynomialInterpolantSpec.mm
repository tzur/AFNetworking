// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBasicPolynomialInterpolant.h"

SpecBegin(LTBasicPolynomialInterpolant)

static const CGFloat kEpsilon = 1e-6;

__block LTBasicPolynomialInterpolant *interpolant;

beforeEach(^{
  std::vector<CGFloat> coefficients{1, 2, 3, 4};
  interpolant = [[LTBasicPolynomialInterpolant alloc] initWithCoefficients:coefficients];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    std::vector<CGFloat> coefficients = interpolant.coefficients;
    expect(coefficients.size()).to.equal(4);
    expect(coefficients[0]).to.equal(1);
    expect(coefficients[1]).to.equal(2);
    expect(coefficients[2]).to.equal(3);
    expect(coefficients[3]).to.equal(4);
  });

  it(@"should raise when attempting to initialize without coefficients", ^{
    expect(^{
      interpolant = [[LTBasicPolynomialInterpolant alloc] initWithCoefficients:{}];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"NSObject protocol", ^{
  context(@"comparison with isEqual:", ^{
    it(@"should return YES when comparing to itself", ^{
      expect([interpolant isEqual:interpolant]).to.beTruthy();
    });

    it(@"should return YES when comparing to an object with the same properties", ^{
      LTBasicPolynomialInterpolant *anotherInterpolant =
          [[LTBasicPolynomialInterpolant alloc] initWithCoefficients:{1, 2, 3, 4}];
      expect([interpolant isEqual:anotherInterpolant]).to.beTruthy();
    });

    it(@"should return NO when comparing to nil", ^{
      LTBasicPolynomialInterpolant *anotherInterpolant = nil;
      expect([interpolant isEqual:anotherInterpolant]).to.beFalsy();
    });

    it(@"should return NO when comparing to an object of a different class", ^{
      expect([interpolant isEqual:[[NSObject alloc] init]]).to.beFalsy();
    });

    it(@"should return NO when comparing to an object with different properties", ^{
      LTBasicPolynomialInterpolant *anotherInterpolant =
          [[LTBasicPolynomialInterpolant alloc] initWithCoefficients:{1, 2, 3}];
      expect([interpolant isEqual:anotherInterpolant]).to.beFalsy();
    });
  });

  context(@"hash", ^{
    it(@"should return the same hash value for equal objects", ^{
      LTBasicPolynomialInterpolant *anotherInterpolant =
          [[LTBasicPolynomialInterpolant alloc] initWithCoefficients:{1, 2, 3, 4}];
      expect([interpolant hash]).to.equal([anotherInterpolant hash]);
    });
  });
});

context(@"NSCopying protocol", ^{
  it(@"should return itself as copy, due to immutability", ^{
    expect([interpolant copy]).to.beIdenticalTo(interpolant);
  });
});

context(@"LTBasicParameterizedObject protocol", ^{
  it(@"should have the correct intrinsic parametric range", ^{
    expect(interpolant.minParametricValue).to.equal(0);
    expect(interpolant.maxParametricValue).to.equal(1);
  });

  it(@"should return the correct linearly interpolated result for a given value", ^{
    interpolant = [[LTBasicPolynomialInterpolant alloc] initWithCoefficients:{2, 5}];
    expect([interpolant floatForParametricValue:-1]).to.beCloseToWithin(3, kEpsilon);
    expect([interpolant floatForParametricValue:0]).to.beCloseToWithin(5, kEpsilon);
    expect([interpolant floatForParametricValue:1]).to.beCloseToWithin(7, kEpsilon);
    expect([interpolant floatForParametricValue:2]).to.beCloseToWithin(9, kEpsilon);
  });

  it(@"should return the correct quadratically interpolated result for a given value", ^{
    interpolant = [[LTBasicPolynomialInterpolant alloc] initWithCoefficients:{1, 2, 3}];
    expect([interpolant floatForParametricValue:-1]).to.beCloseToWithin(2, kEpsilon);
    expect([interpolant floatForParametricValue:0]).to.beCloseToWithin(3, kEpsilon);
    expect([interpolant floatForParametricValue:1]).to.beCloseToWithin(6, kEpsilon);
    expect([interpolant floatForParametricValue:2]).to.beCloseToWithin(11, kEpsilon);
  });

  it(@"should return the correct cubically interpolated result for a given value", ^{
    interpolant = [[LTBasicPolynomialInterpolant alloc] initWithCoefficients:{1, 2, 3, 4}];
    expect([interpolant floatForParametricValue:-1]).to.beCloseToWithin(2, kEpsilon);
    expect([interpolant floatForParametricValue:0]).to.beCloseToWithin(4, kEpsilon);
    expect([interpolant floatForParametricValue:1]).to.beCloseToWithin(10, kEpsilon);
    expect([interpolant floatForParametricValue:2]).to.beCloseToWithin(26, kEpsilon);
  });
});

SpecEnd
