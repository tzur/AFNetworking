// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTPrimitivePolynomialInterpolant.h"

SpecBegin(LTPrimitivePolynomialInterpolant)

static const CGFloat kEpsilon = 1e-6;

__block LTPrimitivePolynomialInterpolant *interpolant;

beforeEach(^{
  CGFloats coefficients{1, 2, 3, 4};
  interpolant = [[LTPrimitivePolynomialInterpolant alloc] initWithCoefficients:coefficients];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    CGFloats coefficients = interpolant.coefficients;
    expect(coefficients.size()).to.equal(4);
    expect(coefficients[0]).to.equal(1);
    expect(coefficients[1]).to.equal(2);
    expect(coefficients[2]).to.equal(3);
    expect(coefficients[3]).to.equal(4);
  });

  it(@"should raise when attempting to initialize without coefficients", ^{
    expect(^{
      interpolant = [[LTPrimitivePolynomialInterpolant alloc] initWithCoefficients:{}];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"LTPrimitiveParameterizedObject protocol", ^{
  it(@"should have the correct intrinsic parametric range", ^{
    expect(interpolant.minParametricValue).to.equal(0);
    expect(interpolant.maxParametricValue).to.equal(1);
  });

  it(@"should return the correct linearly interpolated result for a given value", ^{
    interpolant = [[LTPrimitivePolynomialInterpolant alloc] initWithCoefficients:{2, 5}];
    expect([interpolant floatForParametricValue:-1]).to.beCloseToWithin(3, kEpsilon);
    expect([interpolant floatForParametricValue:0]).to.beCloseToWithin(5, kEpsilon);
    expect([interpolant floatForParametricValue:1]).to.beCloseToWithin(7, kEpsilon);
    expect([interpolant floatForParametricValue:2]).to.beCloseToWithin(9, kEpsilon);
  });

  it(@"should return the correct quadratically interpolated result for a given value", ^{
    interpolant = [[LTPrimitivePolynomialInterpolant alloc] initWithCoefficients:{1, 2, 3}];
    expect([interpolant floatForParametricValue:-1]).to.beCloseToWithin(2, kEpsilon);
    expect([interpolant floatForParametricValue:0]).to.beCloseToWithin(3, kEpsilon);
    expect([interpolant floatForParametricValue:1]).to.beCloseToWithin(6, kEpsilon);
    expect([interpolant floatForParametricValue:2]).to.beCloseToWithin(11, kEpsilon);
  });

  it(@"should return the correct cubically interpolated result for a given value", ^{
    interpolant = [[LTPrimitivePolynomialInterpolant alloc] initWithCoefficients:{1, 2, 3, 4}];
    expect([interpolant floatForParametricValue:-1]).to.beCloseToWithin(2, kEpsilon);
    expect([interpolant floatForParametricValue:0]).to.beCloseToWithin(4, kEpsilon);
    expect([interpolant floatForParametricValue:1]).to.beCloseToWithin(10, kEpsilon);
    expect([interpolant floatForParametricValue:2]).to.beCloseToWithin(26, kEpsilon);
  });
});

SpecEnd
