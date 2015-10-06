// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTDegenerateInterpolationRoutine.h"

#import "LTInterpolationRoutineExamples.h"

SpecBegin(LTDegenerateInterpolationRoutine)

itShouldBehaveLike(kLTInterpolationRoutineFactoryExamples,
  @{kLTInterpolationRoutineFactory: [[LTDegenerateInterpolationRoutineFactory alloc] init],
    kLTInterpolationRoutineClass: [LTDegenerateInterpolationRoutine class]});

itShouldBehaveLike(kLTInterpolationRoutineExamples,
  @{kLTInterpolationRoutineClass: [LTDegenerateInterpolationRoutine class]});

it(@"should always return the single source keyframe", ^{
  InterpolatedObject *object = [[InterpolatedObject alloc] init];
  object.floatToInterpolate = 1;
  object.doubleToInterpolate = 2;
  LTInterpolationRoutine *routine =
      [[LTDegenerateInterpolationRoutine alloc] initWithKeyFrames:@[object]];
  expect([routine valueAtKey:0]).to.equal(object);
  expect([routine valueAtKey:0.5]).to.equal(object);
  expect([routine valueAtKey:1]).to.equal(object);
});

SpecEnd
