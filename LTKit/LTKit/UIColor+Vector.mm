// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "UIColor+Vector.h"

#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"

@implementation UIColor (Vector)

+ (UIColor *)lt_colorWithLTVector:(LTVector4)vector {
  return [UIColor colorWithRed:vector.r() green:vector.g() blue:vector.b() alpha:vector.a()];
}

- (LTVector4)lt_ltVector {
  CGFloat r, g, b, a;
  if ([self getRed:&r green:&g blue:&b alpha:&a]) {
    return LTVector4(r, g, b, a);
  } else if ([self getWhite:&r alpha:&a]) {
    return LTVector4(r, r, r, a);
  }
  LTAssert(NO, @"Invalid color for conversion: %@", self);
}

- (cv::Vec4b)lt_cvVector {
  LTVector4 ltVector = self.lt_ltVector * std::numeric_limits<uchar>::max();
  return cv::Vec4b(ltVector.r(), ltVector.g(), ltVector.b(), ltVector.a());
}

@end
