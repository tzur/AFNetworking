// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBoundaryCondition.h"

@implementation LTSymmetricBoundaryCondition

+ (float)boundaryConditionForPosition:(float)location withSignalLength:(float)length {
  LTParameterAssert(length > 0, @"Length must be positive");

  float base = fmodf(location, length);
  if (base < 0) {
    base += length;
  }

  // Find number of repetitions. On odd repetitions we should mirror the signal, otherwise we keep
  // it as is.
  if ((int)floorf(location / length) % 2) {
    return length - base;
  } else {
    return base;
  }
}

+ (LTVector2)boundaryConditionForPoint:(LTVector2)point withSignalSize:(CGSize)size {
  if (point.x < 0 || point.x >= size.width) {
    point.x = [self boundaryConditionForPosition:point.x withSignalLength:size.width];
  }
  if (point.y < 0 || point.y >= size.height) {
    point.y = [self boundaryConditionForPosition:point.y withSignalLength:size.height];
  }
  return point;
}

@end
