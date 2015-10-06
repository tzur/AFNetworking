// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTLinearInterpolationRoutine.h"

#import "LTInterpolationRoutineExamples.h"

SpecBegin(LTLinearInterpolationRoutine)

itShouldBehaveLike(kLTInterpolationRoutineFactoryExamples,
  @{kLTInterpolationRoutineFactory: [[LTLinearInterpolationRoutineFactory alloc] init],
    kLTInterpolationRoutineClass: [LTLinearInterpolationRoutine class]});

itShouldBehaveLike(kLTInterpolationRoutineExamples,
  @{kLTInterpolationRoutineClass: [LTLinearInterpolationRoutine class]});

context(@"should perform correct linear interpolation", ^{
  __block InterpolatedObject *first;
  __block InterpolatedObject *second;
  __block InterpolatedObject *interpolated;
  __block LTLinearInterpolationRoutine *routine;
  
  beforeEach(^{
    first = [[InterpolatedObject alloc] init];
    second = [[InterpolatedObject alloc] init];
    first.floatToInterpolate = 1;
    second.floatToInterpolate = 2;
    first.doubleToInterpolate = 3;
    second.doubleToInterpolate = 5;
    routine = [[LTLinearInterpolationRoutine alloc] initWithKeyFrames:@[first, second]];
  });
  
  it(@"should return object equal to first keyframe for key 0", ^{
    interpolated = [routine valueAtKey:0];
    expect(interpolated).to.equal(first);
  });
  
  it(@"should return object equal to second keyframe for key 1", ^{
    interpolated = [routine valueAtKey:1];
    expect(interpolated).to.equal(second);
  });
  
  it(@"should return linear combination for values between [0,1]", ^{
    interpolated = [routine valueAtKey:0.25];
    expect(interpolated.floatToInterpolate).to.beCloseTo(1.25);
    expect(interpolated.doubleToInterpolate).to.beCloseTo(3.5);
    interpolated = [routine valueAtKey:0.5];
    expect(interpolated.floatToInterpolate).to.beCloseTo(1.5);
    expect(interpolated.doubleToInterpolate).to.beCloseTo(4);
    interpolated = [routine valueAtKey:0.75];
    expect(interpolated.floatToInterpolate).to.beCloseTo(1.75);
    expect(interpolated.doubleToInterpolate).to.beCloseTo(4.5);
  });
});

SpecEnd
