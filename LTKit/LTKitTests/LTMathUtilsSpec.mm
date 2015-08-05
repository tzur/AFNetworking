// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMathUtils.h"

LTSpecBegin(LTMathUtils)

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

    // Delta should gradually increase.
    for (CGFloat i = 0.1; i <= 0.5; i += 0.1) {
      CGFloat delta = LTSmoothstep(0, 1, i) - LTSmoothstep(0, 1, i - 0.1);
      expect(delta).to.beGreaterThan(previousDelta);
      previousDelta = delta;
    }

    // Delta should gradually decrease.
    previousDelta = 1;
    for (CGFloat i = 0.6; i <= 1.0; i += 0.1) {
      CGFloat delta = LTSmoothstep(0, 1, i) - LTSmoothstep(0, 1, i - 0.1);
      expect(delta).to.beLessThan(previousDelta);
      previousDelta = delta;
    }
  });
});

context(@"half gaussian", ^{
  static const CGFloat kEpsilon = 1e-6;

  it(@"should raise when creating gaussian with non-positive sigma", ^{
    expect(^{
      LTCreateHalfGaussian(5, 0, NO);
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      LTCreateHalfGaussian(5, -1, NO);
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should create half gaussian with the given radius", ^{
    CGFloats gaussian = LTCreateHalfGaussian(4, 2, NO);
    expect(gaussian.size()).to.equal(5);
  });

  it(@"should create half gaussian with the given sigma", ^{
    CGFloats expected({
      1.2151765699650227e-8,
      0.0002676604515298065,
      0.1079819330263797,
      0.7978845608028654
    });

    CGFloats gaussian = LTCreateHalfGaussian(3, 0.5, NO);
    expect(gaussian.size()).to.equal(expected.size());
    for (NSUInteger i = 0; i < expected.size(); ++i) {
      expect(gaussian[i]).to.beCloseToWithin(expected[i], kEpsilon);
    }

    expected = CGFloats({
      0.026995483256594927,
      0.0647587978329471,
      0.12098536225957268,
      0.17603266338215012,
      0.19947114020071635
    });
    gaussian = LTCreateHalfGaussian(4, 2, NO);
    expect(gaussian.size()).to.equal(expected.size());
    for (NSUInteger i = 0; i < expected.size(); ++i) {
      expect(gaussian[i]).to.beCloseToWithin(expected[i], kEpsilon);
    }
  });

  it(@"should normalize weights of the generated half gaussian", ^{
    CGFloats expected({
      1.341055899866556e-8,
      0.0002953872190732951,
      0.1191677094039017,
      0.880536889966466
    });

    CGFloats gaussian = LTCreateHalfGaussian(3, 0.5, YES);
    expect(gaussian.size()).to.equal(expected.size());
    for (NSUInteger i = 0; i < expected.size(); ++i) {
      expect(gaussian[i]).to.beCloseToWithin(expected[i], kEpsilon);
    }
  });
});

LTSpecEnd
