// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMathUtils.h"

SpecBegin(LTMathUtils)

context(@"power of two", ^{
  it(@"should return yes for power of two size", ^{
    expect(LTIsPowerOfTwo(CGSizeMake(64, 128))).to.beTruthy();
  });

  it(@"should return no when one of the dimensions is not a power of two", ^{
    expect(LTIsPowerOfTwo(CGSizeMake(64, 127))).to.beFalsy();
  });

  it(@"should return no when both dimensions are not a power of two", ^{
    expect(LTIsPowerOfTwo(CGSizeMake(63, 127))).to.beFalsy();
  });

  it(@"should return no when size is not integral", ^{
    expect(LTIsPowerOfTwo(CGSizeMake(63.25, 127.5))).to.beFalsy();
  });
});

context(@"smooth step", ^{
  it(@"should return 0 when x is min", ^{
    expect(LTSmoothstep(5, 10, 5)).to.equal(0);
  });

  it(@"should return 1 when x is max", ^{
    expect(LTSmoothstep(5, 10, 10)).to.equal(1);
  });

  it(@"should return 0.5 when x is exactly in the midle of min and max", ^{
    expect(LTSmoothstep(1, 0, 0.5)).to.equal(0.5);
  });

  it(@"should clamp if x is below min", ^{
    expect(LTSmoothstep(5, 10, 3)).to.equal(0);
  });

  it(@"should clamp if x is above max", ^{
    expect(LTSmoothstep(5, 10, 13)).to.equal(1);
  });

  it(@"should interpolate smoothly for x between min and max", ^{
    CGFloat previousDelta = 0.0;

    // Delta should gradualy increase
    for (CGFloat i = 0.1; i <= 0.5; i += 0.1) {
      CGFloat delta = LTSmoothstep(0, 1, i) - LTSmoothstep(0, 1, i - 0.1);
      expect(delta).to.beGreaterThan(previousDelta);
      previousDelta = delta;
    }

    // Delta should gradualy decrease
    previousDelta = 1;
    for (CGFloat i = 0.6; i <= 1.0; i += 0.1) {
      CGFloat delta = LTSmoothstep(0, 1, i) - LTSmoothstep(0, 1, i - 0.1);
      expect(delta).to.beLessThan(previousDelta);
      previousDelta = delta;
    }
  });
});

SpecEnd
