// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCatmullRomInterpolant.h"

#import "LTInterpolationRoutineExamples.h"

SpecBegin(LTCatmullRomInterpolant)

itShouldBehaveLike(kLTInterpolationRoutineFactoryExamples,
  @{kLTInterpolationRoutineFactory: [[LTCatmullRomInterpolantFactory alloc] init],
    kLTInterpolationRoutineClass: [LTCatmullRomInterpolant class]});

itShouldBehaveLike(kLTInterpolationRoutineExamples,
  @{kLTInterpolationRoutineClass: [LTCatmullRomInterpolant class]});

context(@"should perform correct catmull-rom interpolation", ^{
  __block InterpolatedObject *p0;
  __block InterpolatedObject *p1;
  __block InterpolatedObject *p2;
  __block InterpolatedObject *p3;
  __block InterpolatedObject *interpolated;
  __block LTCatmullRomInterpolant *interpolant;
  
  beforeEach(^{
    p0 = [[InterpolatedObject alloc] init];
    p1 = [[InterpolatedObject alloc] init];
    p2 = [[InterpolatedObject alloc] init];
    p3 = [[InterpolatedObject alloc] init];
    p0.floatToInterpolate = 0.25;
    p1.floatToInterpolate = 0.5;
    p2.floatToInterpolate = 1.0 / 3.0;
    p3.floatToInterpolate = 2.0 / 3.0;
    p0.doubleToInterpolate = p3.floatToInterpolate;
    p1.doubleToInterpolate = p2.floatToInterpolate;
    p2.doubleToInterpolate = p1.floatToInterpolate;
    p3.doubleToInterpolate = p0.floatToInterpolate;
    interpolant = [[LTCatmullRomInterpolant alloc] initWithKeyFrames:@[p0, p1, p2, p3]];
  });
  
  it(@"should return object equal to second keyframe for key 0", ^{
    interpolated = [interpolant valueAtKey:0];
    expect(interpolated).to.equal(p1);
  });
  
  it(@"should return object equal to third keyframe for key 1", ^{
    interpolated = [interpolant valueAtKey:1];
    expect(interpolated).to.equal(p2);
  });
  
  // Target values were calculated in matlab.
  it(@"should return the correct interpolation for values between [0,1]", ^{
    interpolated = [interpolant valueAtKey:0.25];
    expect(interpolated.floatToInterpolate).to.beCloseToWithin(0.4759, 1e-4);
    expect(interpolated.doubleToInterpolate).to.beCloseToWithin(0.3496, 1e-4);
    interpolated = [interpolant valueAtKey:0.5];
    expect(interpolated.floatToInterpolate).to.beCloseToWithin(0.4115, 1e-4);
    expect(interpolated.doubleToInterpolate).to.beCloseToWithin(0.4115, 1e-4);
    interpolated = [interpolant valueAtKey:0.75];
    expect(interpolated.floatToInterpolate).to.beCloseToWithin(0.3496, 1e-4);
    expect(interpolated.doubleToInterpolate).to.beCloseToWithin(0.4759, 1e-4);
  });
});

SpecEnd
