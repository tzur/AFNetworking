// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTBoundaryCondition.h"

@implementation LTSymmetricBoundaryCondition

+ (float)boundaryConditionForPosition:(float)location withSignalLength:(int)length {
  float base = fmodf(location, length - 1);
  if (base < 0) base += (length - 1);

  // Find number of repetitions. On odd repetitions we should mirror the signal, otherwise we keep
  // it as is.
  if ((int)floorf(location / (length - 1)) % 2) {
    return length - 1 - base;
  } else {
    return base;
  }
}

+ (GLKVector2)boundaryConditionForPoint:(GLKVector2)point withSignalSize:(cv::Vec2i)size {
  if (point.x < 0 || point.x >= size(0)) {
    point.x = [self boundaryConditionForPosition:point.x withSignalLength:size(0)];
  }
  if (point.y < 0 || point.y >= size(1)) {
    point.y = [self boundaryConditionForPosition:point.y withSignalLength:size(1)];
  }
  return point;
}

@end
