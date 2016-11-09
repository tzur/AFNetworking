// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "CAMOrientationUtils.h"

NS_ASSUME_NONNULL_BEGIN

static void CAMVerifyExifOrientation(int orientation) {
  LTParameterAssert(orientation > 0 && orientation <= 8, @"Exif orientations must be in [1, 8] "
                    "integral range. got: %d", orientation);
}

int CAMClockwiseRotationsForExifOrientation(int orientation) {
  CAMVerifyExifOrientation(orientation);

  int rotations = 0;
  switch (orientation) {
    case 3:
    case 4:
      rotations = 2;
      break;
    case 5:
    case 6:
      rotations = 1;
      break;
    case 7:
    case 8:
      rotations = 3;
      break;
  }
  return rotations;
}

BOOL CAMIsExifOrientationMirrored(int orientation) {
  CAMVerifyExifOrientation(orientation);

  return orientation == 2 || orientation == 4 || orientation == 5 || orientation == 7;;
}

BOOL CAMEqualMirroringForExifOrientations(int first, int second) {
  return CAMIsExifOrientationMirrored(first) == CAMIsExifOrientationMirrored(second);
}

BOOL CAMIsExifOrientationLandscape(int orientation) {
  CAMVerifyExifOrientation(orientation);

  return orientation > 4;
}

NS_ASSUME_NONNULL_END
