// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTDegenerateInterpolant.h"

#import "LTPolynomialInterpolantExamples.h"

SpecBegin(LTDegenerateInterpolant)

itShouldBehaveLike(LTPolynomialInterpolantFactoryExamples,
  @{LTPolynomialInterpolantFactory: [[LTDegenerateInterpolantFactory alloc] init],
    LTPolynomialInterpolantClass: [LTDegenerateInterpolant class]});

itShouldBehaveLike(LTPolynomialInterpolantExamples,
  @{LTPolynomialInterpolantClass: [LTDegenerateInterpolant class]});

it(@"should always return the single source keyframe", ^{
  InterpolatedObject *object = [[InterpolatedObject alloc] init];
  object.floatToInterpolate = 1;
  object.doubleToInterpolate = 2;
  LTPolynomialInterpolant *interpolant =
      [[LTDegenerateInterpolant alloc] initWithKeyFrames:@[object]];
  expect([interpolant valueAtKey:0]).to.equal(object);
  expect([interpolant valueAtKey:0.5]).to.equal(object);
  expect([interpolant valueAtKey:1]).to.equal(object);
});

SpecEnd
