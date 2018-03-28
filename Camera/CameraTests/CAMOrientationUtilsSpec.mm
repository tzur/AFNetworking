// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "CAMOrientationUtils.h"

SpecBegin(CAMOrientationUtils)

context(@"input verification", ^{
  static const int kBadExifOrientationAbove = 9;
  static const int kBadExifOrientationBelow = -1;
  static const int kValidExifOrientation = 6;

  it(@"should raise for orientation above range", ^{
    expect (^{
      CAMIsExifOrientationMirrored(kBadExifOrientationAbove);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise for orientation below range", ^{
    expect (^{
      CAMIsExifOrientationMirrored(kBadExifOrientationBelow);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not raise for valid orientation", ^{
    expect (^{
      CAMIsExifOrientationMirrored(kValidExifOrientation);
    }).toNot.raiseAny();
  });
});

context(@"orientation and landscape coherence", ^{
  static const int minExifOrientation = 1;
  static const int maxExifOrientation = 8;

  it(@"should give 90 or 270 degrees rotation for landscape orientations", ^{
    for (int i = minExifOrientation; i <= maxExifOrientation; ++i) {
      int cwRotations = CAMClockwiseRotationsForExifOrientation(i);
      BOOL swapSides = CAMIsExifOrientationLandscape(i);
      expect(((cwRotations + 4) % 2) == swapSides).to.beTruthy();
    }
  });
});

context(@"integration", ^{
  it(@"should give correct clockwise rotations", ^{
    expect(CAMClockwiseRotationsForExifOrientation(5)).to.equal(1);
  });

  it(@"should give correct mirroring", ^{
    expect(CAMIsExifOrientationMirrored(5)).to.beTruthy();
  });

  it(@"should give correct equal mirroring", ^{
    expect(CAMEqualMirroringForExifOrientations(2, 7)).to.beTruthy();
  });

  it(@"should give correct landscape flag", ^{
    expect(CAMIsExifOrientationLandscape(2)).to.beFalsy();
  });
});

SpecEnd
