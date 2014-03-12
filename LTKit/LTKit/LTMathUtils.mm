// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTMathUtils.h"

BOOL LTIsPowerOfTwo(CGFloat value) {
  int intValue = value;
  return value == intValue && !(intValue & (intValue - 1));
}

BOOL LTIsPowerOfTwo(CGSize size) {
  int width = size.width;
  int height = size.height;

  if (width != size.width || height != size.height) {
    return NO;
  }

  return !((width & (width - 1)) || (height & (height - 1)));
}
